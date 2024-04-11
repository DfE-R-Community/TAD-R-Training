
# Let's go back to the data as it was before -----------------------------------

# nycflights13 has data about flights
flights <- nycflights13::flights %>%
  select(
    year,
    month,
    day,
    arr_delay,
    tailnum,
    distance,
    air_time)

colnames(flights)

# but the package also has data about planes
planes <- nycflights13::planes

colnames(planes)

# what if we want to answer the question - are some manufacturers' planes more
# likely to be late than others?  We need to link information in PLANES to
# information in FLIGHTS

# We do this using a JOIN
flights_and_planes <- left_join(
  x = flights,
  y = planes,
  by = 'tailnum'
)

# there's a 'year' column in both sheets - so R has to work out what to do with
# them
colnames(flights_and_planes)

# we can control this behaviour here
flights_and_planes <- left_join(
  x = flights,
  y = planes,
  by = 'tailnum',
  suffix = c('_flights', '_planes')
)

# some rows in x have no match:
flights_and_planes %>% filter(is.na(manufacturer))

# now we can summarise delay by manufacturer:
flights_and_planes %>%
  group_by(manufacturer) %>%
  summarise(median_arrival_delay = median(arr_delay, na.rm = T))

flights_and_planes %>%
  ggplot(aes(x = arr_delay,
             y = manufacturer)) +
  geom_boxplot()

# other kinds of joins ------------------------

## FULL JOIN -----------------------------------

# combine all rows from flights and planes
full_join_example <- full_join(flights,
                               planes)

## ANTI JOIN ----------------------------------

# what rows are in flights but not in planes?
anti_join_flights <- anti_join(flights, 
                               planes, 
                               by = 'tailnum')

# what rows are in planes but not in flights?
anti_join_planes <- anti_join(planes, 
                               flights, 
                               by = 'tailnum')

## RIGHT JOIN --------------------------------

# join flights onto planes
right_join_example <- right_join(
  flights,
  planes,
  by = 'tailnum',
  suffix = c('.flights',
             '.planes')
)
