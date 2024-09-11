
options(scipen = 100)

# Let's try to answer a useful question. What kinds of flights are more commonly
# late?

# import data ------------------------------------------------------------------

flights <- nycflights13::flights
airplanes <- nycflights13::planes
airports <- nycflights13::airports

# clean data -------------------------------------------------------------------

# some of our aeroplane manufacturer data looks a bit messy.  let's tidy it up.
View(airplanes %>%
       count(manufacturer) %>%
       arrange(desc(n)))

airplanes_clean <- airplanes %>%
  mutate(
    manufacturer_clean = case_when(
      # this function, from data.table, means 'if manufacturer contains x'
      manufacturer %like% 'AIRBUS' ~ 'AIRBUS',
      manufacturer %like% 'MCDONNELL DOUGLAS' ~ 'MCDONNELL DOUGLAS',
      manufacturer %like% 'DOUGLAS' ~ 'MCDONNELL DOUGLAS',
      TRUE ~ manufacturer
    )
  )

airplanes_clean %>%
  count(manufacturer, manufacturer_clean) %>%
  arrange(desc(n))

# exploratory analysis ---------------------------------------------------------

# we principally care about arrival delay - that's how late the plane is
flights_proc <- flights %>%
  left_join(airplanes_clean,
            by = 'tailnum',
            suffix = c('_flight', '_plane')) %>%
  left_join(airports,
            by = c('dest' = 'faa'),
            suffix = c('_flight', '_airport')) %>%
  filter(!is.na(arr_delay)) %>%
  mutate(is_late = arr_delay > 20) %>%
  
  rename(airport_name = name)

# note that both of our joins are incomplete.  'Rows only in x' shows flights
# with no matching plane or airport, respectively
flights_with_no_matched_plane <- anti_join(flights, airplanes_clean, by = 'tailnum')
planes_with_no_matched_flight <- anti_join(airplanes_clean, flights, by = 'tailnum')

# how about airports?
flights_with_no_matched_airport <- anti_join(flights, airports, by = c('dest' = 'faa'))

# These seem to be airports in American jurisdictions but not in the US - e.g.
# puerto rico, St. Thomas, etc.
flights_with_no_matched_airport %>%
  count(dest)

## DELAY BY ORIGIN -------------------------------------------------------------

# which routes have the worst delay stats?
flights_proc %>%
  group_by(origin, dest, airport_name) %>%
  summarise(
    flights_n = n(),
    arr_delay_median = median(arr_delay),
    arr_delay_q80 = quantile(arr_delay, 0.8),
    distance_median = median(distance),
    p_late = mean(is_late)
  ) %>%
  
  arrange(desc(arr_delay_median))

# what if we want to make this into a graph?  Some handy additions
late_by_route <- flights_proc %>%
  
  # calculate some values by destination only, for use with ggplot later
  group_by(dest) %>%
  mutate(p_late_dest = mean(is_late),
         med_delay_dest = median(arr_delay)) %>%
  
  ungroup() %>%
  
  # calculate some summary stats by origin and destination, including the
  # p_late_dest var so we don't drop it
  group_by(origin, dest, airport_name, p_late_dest, med_delay_dest) %>%
  summarise(
    flights_n = n(),
    arr_delay_median = median(arr_delay),
    distance_median = median(distance),
    p_late = mean(is_late)
  ) %>%
  
  # drop any single destination with less than 5000 flights to it, to reduce noise
  filter(flights_n > 1500) %>%
  
  arrange(desc(p_late))

# make a wide table for readability:
late_by_route %>%
  pivot_wider(id_cols = dest,
              names_from = origin,
              values_from = p_late)

late_by_route %>%
  filter(!is.na(airport_name)) %>%
  ggplot(aes(
    y = reorder(airport_name, p_late_dest),
    x = p_late,
    colour = origin,
    size = flights_n
  )) +
  geom_point() +
  ylab('Destination airport') +
  xlab('Proportion of late flights') +
  scale_size_continuous(range = c(2, 6), trans = 'log10')

late_by_route %>%
  filter(!is.na(airport_name)) %>%
  ggplot(aes(
    y = reorder(airport_name, med_delay_dest),
    x = arr_delay_median,
    colour = origin,
    size = flights_n
  )) +
  geom_point() +
  ylab('Destination airport') +
  xlab('Median arrival delay, mins')

## DELAY BY MANUFACTURER -------------------------------------------------------

# summarise in a table
flights_proc %>%
  group_by(manufacturer) %>%
  summarise(flights_n = n(),
            arr_delay_median = median(arr_delay)) %>%
  
  arrange(desc(flights_n))

# lets summarise with standard error so we can plot some error bars on a graph
flights_by_manufacturer <- flights_proc %>%
  group_by(manufacturer_clean) %>%
  summarise(
    flights_n = n(),
    arr_delay_mean = mean(arr_delay),
    arr_delay_se = sd(arr_delay) / sqrt(flights_n)
  ) %>%
  
  arrange(desc(flights_n)) %>%
  
  filter(!is.na(manufacturer_clean))

# looks like CANADAIR has more delays on average, and boeing less - but that
# might be because of the routes that they tend to fly!
flights_by_manufacturer %>%
  filter(flights_n > 500) %>%
  ggplot(
    aes(
      y = reorder(manufacturer_clean, arr_delay_mean),
      
      x = arr_delay_mean,
      xmin = arr_delay_mean - 1.96 * arr_delay_se,
      xmax = arr_delay_mean + 1.96 * arr_delay_se
    )
  ) +
  
  geom_point() +
  geom_errorbar(width = 0.5) +
  ylab('Manufacturer') +
  xlab('Mean arrival delay, mins')

## DELAY BY DISTANCE -----------------------------------------------------------

# does flight distance affect delay?

# very hard to tell with all the data - it's too noisy and some flights have
# very big delays
flights_proc %>%
  slice_sample(prop = 0.05) %>%
  ggplot(aes(x = distance, y = arr_delay)) +
  
  geom_smooth() +
  geom_point()

# we can collapse to percentiles to see what the trend is like!
distance_perc <- flights_proc %>%
  # group into 100 equally sized groups
  mutate(distance_group = ntile(distance, 100)) %>%
  group_by(distance_group) %>%
  summarise(distance_mean = mean(distance),
            delay_mean = mean(arr_delay))

# plot the mean delay for each group! Now a trend is slightly easier to pick out
# from the noise.
distance_perc %>%
  ggplot(aes(x = distance_mean, y = delay_mean)) +
  
  geom_point() +
  geom_smooth()

## DATA FOR MODELLING ----------------------------------------------------------

hist(flights_proc$distance)

model_data <- flights_proc %>%
  select(arr_delay, distance, origin, dest, manufacturer_clean, carrier) %>%
  
  # remove any row with any NAs. NOTE!  Not good practice for analysis!  Just
  # doing it to show you how to use the tools!
  filter(if_all(.cols = everything(), .fns = ~ !is.na(.x))) %>%
  
  # convert distance into thousands of k for easier interpreta
  mutate(distance_thou = distance / 1000)

# run a simple model
simple_lm <- lm(
  arr_delay ~ splines::ns(distance_thou, 3)
  + origin
  + dest
  + manufacturer_clean
  + carrier,
  data = model_data
)

summary(simple_lm)

# so now let's compare the different manufacturers on equal footing:

# we need create a dataframe to hold the flights we want to compare:
prediction_data <- model_data %>%
  filter(origin == 'JFK', dest == 'LAX') %>%
  
  slice_head(n = 1) %>%
  
  select(origin, dest, distance_thou) %>%
  
  # add all combinations of manufacturer and carrier
  expand_grid(
    manufacturer_clean = unique(model_data$manufacturer_clean),
    carrier = unique(model_data$carrier)
  )

# predict the arrival delay using our model and then bind it on.  Note that the
# order of the data will be the same.
predicted_arr_delays <- predict(simple_lm, newdata = prediction_data)

predicted_arr_delays

prediction_data$arr_delay_pred <- predicted_arr_delays

# make a nice tile chart to show our predictions
prediction_data %>%
  group_by(manufacturer_clean) %>%
  mutate(mean_delay_mf = mean(arr_delay_pred)) %>%
  group_by(carrier) %>%
  mutate(mean_delay_carrier = mean(arr_delay_pred)) %>%
  ggplot(aes(
    y = reorder(manufacturer_clean, mean_delay_mf),
    x = reorder(carrier, mean_delay_carrier),
    fill = arr_delay_pred,
    label = round(arr_delay_pred)
  )) +
  
  geom_tile(linewidth = 1, colour = 'black') +
  
  geom_text(colour = 'black') +
  
  xlab('Carrier') +
  ylab('Manufacturer') +
  
  scale_fill_gradient2(
    midpoint = 0,
    high = 'coral3',
    low = 'cornflowerblue'
  )
