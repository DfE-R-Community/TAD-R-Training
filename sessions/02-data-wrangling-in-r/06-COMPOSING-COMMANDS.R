library(janitor)

options(scipen = 100)

# WHAT PREDICTS ARRIVAL DELAYS? -------------------------------------------

flights <- nycflights13::flights %>%
  filter(!is.na(tailnum))

# check what combination of variables gives us no duplicates
flights %>%
  get_dupes(year, month, day, sched_dep_time, tailnum, flight)


flights_processed <- flights %>%
  
  slice_sample(prop = 0.1) %>%
  
  # remove flights that didn't arrive
  filter(!is.na(arr_time),
         !is.na(dep_time),
         !is.na(tailnum),
         !is.na(arr_delay)) %>%
  
  # create a more useful date/time variable
  mutate(      
    dmy = paste0(day, "-", month, "-", year),
    date = as.Date(dmy, format = '%d-%m-%Y'),
    
    across(.cols = c(sched_dep_time,
                     sched_arr_time,
                     arr_time,
                     dep_time),
           
           # convert the hour:minute format to fractional hours
           .fns = ~ case_when(is.na(.x) ~ as.numeric(NA),
                              nchar(.x) %in% 1:2 ~ as.numeric(.x / 60),
                              nchar(.x) == 3 ~ as.numeric(substr(.x, 1, 1)) + as.numeric(substr(.x, 2, 3)) / 60,
                              nchar(.x) == 4 ~ as.numeric(substr(.x, 1, 1)) + as.numeric(substr(.x, 2, 3)) / 60)
           ),
    
    arr_delay_hrs = arr_delay / 60,
    dep_delay_hrs = dep_delay / 60,
    
    distance_log_10 = log10(distance)
    
  ) %>%
  
  # drop cols we don't want
  select(date, 
         tailnum, 
         origin, 
         dest, 
         distance, 
         distance_log_10,
         sched_dep_time, 
         dep_delay, 
         dep_delay_hrs,
         sched_arr_time, 
         arr_delay,
         arr_delay_hrs)

# some descriptive statistics first --------------------------------------------

flights_processed %>%
  group_by(origin) %>%
  summarise(mean_arr_delay = mean(arr_delay),
            median_arr_delay = median(arr_delay))

flights_processed %>%
  group_by(dest) %>%
  summarise(mean_arr_delay = mean(arr_delay),
            median_arr_delay = median(arr_delay))

flights_processed %>%
  mutate(binned_distance = ntile(distance, n = 10)) %>%
  group_by(binned_distance) %>%
  summarise(n_flights = n(),
            min_bin = min(distance),
            max_bin = max(distance),
            mean_arr_delay = mean(arr_delay),
            median_arr_delay = median(arr_delay))

flights_processed %>%
  mutate(binned_distance = ntile(distance, n = 10)) %>%
  group_by(binned_distance) %>%
  summarise(n_flights = n(),
            min_bin = min(distance),
            max_bin = max(distance),
            mean_arr_delay = mean(arr_delay),
            median_arr_delay = median(arr_delay)) %>%
  ggplot(aes(x = (min_bin + max_bin) / 2,
             y = mean_arr_delay)) +
  geom_point()

flights_processed %>%
  ggplot(aes(x = distance,
             y = arr_delay)) +
  geom_point() +
  scale_y_continuous(trans = 'pseudo_log')


# run a model -------------------------------------------------------------

simple_arr_model <- (lm(arr_delay ~ origin + 
                        splines::ns(distance_log_10, 3),
           
           data = flights_processed))

plot(effects::allEffects(simple_arr_model))
