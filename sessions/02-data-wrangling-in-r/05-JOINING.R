
library(tidyverse)
library(tidylog)
library(janitor)
library(nycflights13)

# Joins are a very powerful tool, but it can be easy to get confused when
# working with them - especially when your data is messy.  We're going to work
# through an example joining FLIGHTS data to data about PLANES.

# Check-list to work through before you start joining:

# A. Do I know what the identifiers are for my data sources, and how they're
# structured?

# For 'flights', we have 'tailnum', which identifies each plane, but many rows
# share the same tailnum. 'planes' has one row per tailnum

# B. Do I have duplicates?  Note that what counts as a 'duplicate' depends on
# what you want out of your data.

flights <- nycflights13::flights %>%
  select(
    year,
    month,
    day,
    dep_time,
    arr_delay,
    tailnum,
    distance,
    air_time)

planes <- nycflights13::planes

# check for any duplicates using all columns

# we have total some duplicates - flights with missing tailnums.  Looks like they
# never took off.  Probably need to remove these, or otherwise account for them.
flights %>% get_dupes()

# remove flights that never left
flights <- nycflights13::flights %>%
  filter(!is.na(dep_time))

# we have lots of duplicate tailnums because planes make many flights in a year.
# This isn't a problem!
flights %>% get_dupes(tailnum)

# how about duplicates by month and day? Still duplicates here, because some
# planes make multiple flights in a day. Also not a problem!
flights %>% get_dupes(tailnum, month, day)

# what if we add departure time? No duplicates.  So this combination of
# variables gives us unique identifiers for each row.
flights %>% get_dupes(tailnum, month, day, dep_time)

# planes is more straightforward.  One row per tailnum. No dupes.
planes %>% get_dupes(tailnum)

# C. Do I have any NAs in my shared variables?  These can cause problems, often
# because they are unintentional duplicates.

# we did have NAs in this column in flights but we've removed them already
flights %>% filter(is.na(tailnum))
planes %>% filter(is.na(tailnum))

test_flights <- data.frame(
  tailnum = c(1, 2, 3, NA, NA),
  departed = c(10, 11, 23, 15, 6)
)

test_planes <- data.frame(
  tailnum = c(1, 2, 3, 3, NA, NA),
  year_manufactured = c(2010, 2023, 2010, 2019, 1998, 1994)
)

# when we join these datasets together, the NAs are cross-joined.  All NAs in
# flights are joined to all NAs in planes.  This is a many-to-many join, and we
# generally want to avoid it.
left_join(test_flights,
          test_planes)

# we can tell R not to match NAs but we can still get cross-joins when we have
# unexpected duplicates in our data
messy_join <- left_join(test_flights,
          test_planes,
          na_matches = 'never')

messy_join

# if you're not using tidylog, check the number of rows before and after your
# join:
nrow(test_flights)
nrow(messy_join)

if ( nrow(test_flights) != nrow(messy_join) ) {
  
  stop("flights-planes data contains more rows than flights alone. Check for duplicates.")
  
}

# SUMMARY: 

# before you join two datasets, it's helpful to understand:
# - how it's structured
# - what columns uniquely identify a row of data in each
# - what columns are shared between the datasets
# - which columns you want to join on
# - whether you have sufficiently dealt with duplicates in the data

# Most problems in joining can be avoided by improving our understanding the
# data, and/or addressing data problems before joining.

# A tangent on de-duplication ---------------------------------------------------

# generating some data for the example:

# here we have some data on teachers taking further professional qualifications.
# At various points in the process, DfE certifies that they have reached a given
# stage, so funding can be sent to the relevant training provider.
teachers_npqs <- expand_grid(
  teacher_id = 1:30,
  stage = c(1, 2, 3, 4)
) %>%
  mutate(certified = sample(c(0, 1), n(), TRUE)) %>%
  filter(certified == 1) %>%
  slice_sample(prop = 1) %>%
  arrange(teacher_id)

# we want to produce some statistics about each teacher, so we can distinct() by
# teacher ID:
teachers_npqs %>%
  distinct(teacher_id, .keep_all = TRUE)

# but which row does this procedure keep? The first row is preserved.  This
# means that the 'stage' variable is determined by the order of the dataset.
# It's much safer to be EXPLICIT about your deduplication.  This way, we know
# what the code is doing.  

# Same often goes for NAs - they're easy to ignore but you will probably have to
# deal with them eventually.

# e.g. we only want to keep the LATEST stage for each teacher:
teachers_npq_latest <- teachers_npqs %>%
  group_by(teacher_id) %>%
  mutate(stage_latest = max(stage)) %>%
  filter(stage == stage_latest)

teachers_npq_latest %>%
  ungroup() %>%
  count(stage_latest) %>%
  ggplot(aes(x = stage_latest,
             y = n)) +
  geom_col(fill = 'coral')

# Let's go back to the data as it was before -----------------------------------

# nycflights13 has data about flights
flights <- nycflights13::flights %>%
  select(
    year,
    month,
    day,
    arr_delay,
    dep_time,
    tailnum,
    distance,
    air_time) %>%
  
  filter(!is.na(dep_time))

colnames(flights)

# but the package also has data about planes
planes <- nycflights13::planes

colnames(planes)

# what if we want to answer the question - are some manufacturers' planes more
# likely to be late than others?  We need to link information in PLANES to
# information in FLIGHTS

# We do this using a JOIN

# note R tells us what columns have been joined on.  If we don't specify, we
# join on all shared columns.  This is a problem because flights$year means
# something different to planes$year
flights_and_planes <- left_join(
  x = flights,
  y = planes)

# year the flight occurred - all 2013
hist(flights$year)

# year the plane was manufactured (?)
hist(planes$year)

# so let's specify that we want to join on tailnumber only - a unique ID that
# identifies each plane.
flights_and_planes <- left_join(
  x = flights,
  y = planes,
  by = 'tailnum'
)

# if tailnum had different names in the different datasets, we'd use the
# formulation below. I've added year as well to show what you'd do for multiple
# columns
flights_and_planes <- left_join(
  x = flights,
  y = planes,
  by = c('tailnum' = 'tailnum', 
         'year' = 'year')
)

flights_and_planes <- left_join(
  x = flights,
  y = planes,
  by = 'tailnum'
)

# there's a 'year' column in both sheets - so R has to work out what to do with
# them.  By default, it adds a '.x' and '.y' so you can distinguish them.
colnames(flights_and_planes)

# we can control this behaviour using 'suffix'. This makes it much easier to
# understand what the columns mean when you look at the dataset and try to work
# out what to do.
flights_and_planes <- left_join(
  x = flights,
  y = planes,
  by = 'tailnum',
  suffix = c('_flights', '_planes')
)

# alternatively, you can rename the column beforehand:
planes <- planes %>%
  rename(year_manufactured = year)

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
  filter(!is.na(manufacturer)) %>%
  group_by(manufacturer) %>%
  mutate(median_manf_delay = median(arr_delay, na.rm = T)) %>%
  ggplot(aes(x = arr_delay,
             y = reorder(manufacturer, median_manf_delay))) +
  geom_boxplot() +
  scale_x_continuous(trans = scales::transform_pseudo_log(sigma = 50)) +
  ylab('') +
  theme(legend.position = 'none')

# other kinds of joins ---------------------------------------------------------

# left joins are the most common type of join.  They match all rows in Y which
# exist in X.

# Left joins are most commonly used when linking data from a new data source to
# a 'spine' variable.  Here the 'spine' is the tail-number, and we want to
# pull in data from other sources using that information.

## FULL JOIN -------------------------------------------------------------------

# combine ALL rows from flights and planes
full_join_example <- full_join(flights,
                               planes)

# most useful when you're combining two data sources with no clear hierarchy.
# E.g. a list of teachers on a programme from data source A and a second list
# from data source B which should match (but don't)

## ANTI JOIN ----------------------------------

# what rows are in flights but not in planes?
flights_not_planes <- anti_join(flights, 
                               planes, 
                               by = 'tailnum')

# 721 tail numbers that don't have matching planes info.  Note similar pattern.
# Also 2512 flights with no tailnum recorded. We should have investigated that
# already!
flights_not_planes %>%
  count(tailnum) %>%
  arrange(desc(n))

# what rows are in planes but not in flights?
planes_not_flights <- anti_join(planes, 
                               flights, 
                               by = 'tailnum')

## RIGHT JOIN --------------------------------

# right join is just the reverse of a left join.  Instead of keeping everything
# in X, we keep only rows which match in Y.

# join flights onto planes
right_join_example <- right_join(
  flights,
  planes,
  by = 'tailnum',
  suffix = c('.flights',
             '.planes')
)

## INNER JOINS -----------------------------

inner_join_example <- inner_join(
  flights,
  planes,
  by = 'tailnum'
)

# a more complex join scenario -------------------------------------------------

# imagine that we have inspection data for 5000 of the planes.  We know when the
# inspection took place.  We want to look at the behaviour of planes before and
# after they failed a random inspection.
inspections <- data.frame(
  tailnum = sample(flights$tailnum, 5000, TRUE),
  inspection_id = 1:5000,
  year = 2013,
  month = sample(1:12, 5000, TRUE),
  day = sample(1:28, 5000, TRUE),
  rating = rnorm(5000, 5.5, 2)
)

# our naive join doesn't work very well! That's because we're joining by year,
# month, day and tailnum, so a join is only found if the plane was inspected the
# same day it flew.
left_join(flights,
          inspections)

# okay, let's just join by tailnum then! this produces loads of duplicates -
# some planes have multiple inspections, and multiple flights - so each flight
# is joined to each inspection.
left_join(flights,
          inspections,
          by = c('tailnum'),
          suffix = c('.flights', '.inspection'))

# make a one-to-many join ------------------------------------------------------

# in this case, we need to refine our analytical question. We could try to
# summarise our inspection data to make joining cleaner.  In this case, we could
# summarise the inspection data.

inspections_summary <- inspections %>%
  group_by(tailnum) %>%
  summarise(n_inspections = n(),
            inspection_latest = max(ymd(paste(year, month, day, sep = "-"))),
            inspection_rating_mean = mean(rating))

inspections_summary  

# now we have no duplicates
flights_and_inspections <- left_join(flights, inspections_summary)

flights_and_inspections %>%
  filter(!is.na(inspection_latest)) %>%
  group_by(tailnum) %>%
  summarise(arr_delay_median = median(arr_delay, na.rm = T),
            n_flights = n(),
            inspection_rating_mean = first(inspection_rating_mean)) %>%
  ggplot(aes(x = n_flights,
             y = inspection_rating_mean)) +
  
  geom_point()

# or we could do the cross join and then deduplicate:
flights_and_inspections_cross_join <- inner_join(
  flights,
  inspections,
  by = c('tailnum'),
  suffix = c('.flights', '.inspection')
)

# our data now contains one row for each flight * one row for each inspection

# lets sample a flight at random and think about how we might deal with this
flights_and_inspections_sample <- flights_and_inspections_cross_join %>% 
  filter(tailnum == 'N24211')

# 3 inspections
inspections %>%
  filter(tailnum == 'N24211')

# 130 flights
flights %>% 
  filter(tailnum == 'N24211')

# first, let's filter out all combinations of inspection and flight where the
# inspection was before the flight. We're interested in what happens after an
# inspection, not before.
flights_and_inspections_sample <- flights_and_inspections_sample %>%
  mutate(date_flight = ymd(paste(2013, month.flights, day.flights, sep = ",")),
         date_inspection = ymd(paste(2013, month.inspection, day.inspection, sep = ",")),
         # positive means after the inspection
         time_gap = date_flight - date_inspection) %>%
  
  filter(time_gap > 0)

#  for each flight, we only want to keep the inspection that was the most recent
flights_and_inspections_sample_dedup <- flights_and_inspections_sample %>%
  group_by(tailnum,
           date_flight,
           dep_time
           ) %>%
  
  filter(time_gap == min(time_gap))

# no duplicates remain!
flights_and_inspections_sample_dedup %>%
  get_dupes(tailnum,
            date_flight,
            dep_time)

# apply to all our data
flights_and_inspections_full <- flights_and_inspections_cross_join  %>%
  mutate(date_flight = ymd(paste(2013, month.flights, day.flights, sep = ",")),
         date_inspection = ymd(paste(2013, month.inspection, day.inspection, sep = ",")),
         # positive means after the inspection
         time_gap = date_flight - date_inspection) %>%
  
  filter(time_gap > 0) %>%
  group_by(tailnum,
           date_flight,
           dep_time
  ) %>%
  
  filter(time_gap == min(time_gap))
  

# now we can plot (for our single example plane) whether arr delay got worse or
# better over time after an inspection:
flights_and_inspections_full %>%
  
  filter(time_gap <= 150) %>%
  
  group_by(time_gap) %>%
  summarise(arr_delay_mean = mean(arr_delay, na.rm = T)) %>%
  
  ggplot(aes(x = time_gap,
            y = arr_delay_mean)) +
  
  geom_smooth() +
  geom_point()
