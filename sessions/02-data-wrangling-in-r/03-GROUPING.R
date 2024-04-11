
# GROUP BY / SUMMARISE ---------------------------------------------------------

# Often, when our data is TIDY, we need to use information that is spread across
# many rows to answer our questions.  This is what GROUP BY is for.

# Imagine that GROUP BY chops your dataframe up into many smaller dataframes,
# based on the variables you have grouped by.  Any operations afterwards will be
# carried out on those subgroups.

# How many flights did each plane do in the year?
flights_per_plane <- flights %>%
  group_by(tailnum) %>%
  mutate(n_flights = n())

# we can also SUMMARISE to collapse each of these sub-tables to the summarised
# values
flights_per_plane <- flights %>%
  filter(!is.na(dep_time) & !is.na(arr_time)) %>%
  group_by(tailnum) %>%
  summarise(n_flights = n(),
            average_dep_delay_time = mean(dep_delay))

# we can group by multiple variables
flights_per_plane_per_origin <- flights %>%
  group_by(tailnum, origin) %>%
  summarise(n_flights = n(),
            first_flight_month = first(month)) %>%
  
  ungroup()

# a shortcut:
flights %>%
  group_by(...) %>%
  summarise(n = n())

flights %>%
  count(tailnum, origin)

flights %>%
  count(tailnum, origin, arr_delay > 10)

# GROUP AND FILTER -------------------------------------------------------------

# Show flights for planes that arrive late on average
often_late_planes <- flights %>%
  group_by(tailnum) %>%
  filter(mean(arr_delay) > 0)

often_late_planes <- flights %>%
  filter(mean(arr_delay, na.rm = T) > 0) %>%
  group_by(tailnum)

# Show flights for planes that have never arrived late
never_late_planes <- flights %>%
  group_by(tailnum) %>%
  filter(all(arr_delay <= 0))

any_late_planes <- flights %>%
  group_by(tailnum) %>%
  filter(any(arr_delay > 0))

# ANSWERING QUESTIONS ----------------------------------------------------------

# which origin airport has the most departure delay?
flights %>%
  filter(!is.na(dep_time) & !is.na(arr_time)) %>%
  group_by(origin) %>%
  summarise(total_late_time = sum(dep_delay) / 60,
            average_late_time = mean(dep_delay),
            proportion_late_flights = mean(dep_delay > 0),
            number_late_flights = sum(dep_delay > 0),
            proportion_early_flights = mean(dep_delay < 0))

# EXAM QUESTIONS ----------------------------------------------------------------

# I want to fly to BOS.  I want my flight to ARRIVE ON TIME and I don't want it
# to be cancelled.  Which origin airport should I choose for the best flight
# experience?

boston_flight_plans <- flights %>%
  filter(dest == 'BOS') %>%
  group_by(origin) %>%
  summarise(n_flights = n(),
            average_arrival_delay = mean(arr_delay, na.rm = T),
            proportion_arrive_late = mean(arrived_late, na.rm = T),
            proportion_did_not_depart = mean(did_not_depart))

# Are any months worse for departure delays?
departure_by_month <- flights %>%
  filter(!is.na(dep_time) & !is.na(arr_time)) %>%
  group_by(month, origin) %>%
  summarise(n = n(),
            average_departure_delay = mean(dep_delay),
            proportion_depart_late = mean(dep_delay > 0))

departure_by_month %>%
  ggplot(aes(x = factor(month),
             y = proportion_depart_late,
             colour = origin,
             group = origin)) +
  geom_point() +
  geom_line()
