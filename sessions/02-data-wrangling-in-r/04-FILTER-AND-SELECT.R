
# Some tips and tricks for filtering and selecting -----------------------------


# SELECT -----------------------------------------------------------------------

# Note: some people think you should keep variables around as long as possible,
# because you might need them in the future and dropping them doesn't do you
# that much good.  Others prefer their data.frames to have only the columns that
# they need and are happy to spend a lot of time scratching their heads about
# why they can't find x or y column that they dropped 150 lines of code ago.
# This is a matter of personal preference as far as I can see.

# Useful for picking out particular columns
flights %>%
  select(tailnum, dep_time, dest)

# all columns between tailnum and dest
flights %>%
  select(tailnum:dest)

# all columns containing the word 'time'
flights %>%
  select(contains('time'))

# columns ending with 'time'
flights %>%
  select(-ends_with('temp'))

# columns start with 'arr'
flights %>%
  select(starts_with('arr'))

# numeric columns
flights %>%
  select(where(is.numeric),
         time_hour)

# drop some columns
flights %>%
  select(-(tailnum:air_time))

# drop many columns
flights %>%
  select(-everything())

# SELECT to rename -------------------------------------------------------------

# you can use SELECT like this to rename columns
flights %>%
  select(original_airport_location = origin,
         the_airport_the_plane_is_going_to = dest)

# I personally prefer using RENAME because it's more explicit.  It also doesn't
# really require much additional code.
flights %>%
  rename(original_airport_location = origin,
         the_airport_the_plane_is_going_to = dest)

# FILTER -----------------------------------------------------------------------

# FILTER takes a logical statement and drops rows that don't get a TRUE

# filter on a variable
flights %>%
  filter(origin == 'LGA')

flights %>%
  filter(origin %in% c('LGA', 'JFK'))

# filter on many variables
flights %>%
  filter(origin == 'LGA',
           dest == 'BOS',
           dep_time > 2300)

# same as the above
flights %>%
  filter(origin == 'LGA' &
         dest == 'BOS' &
         dep_time > 2300)

# make really horribly complicated filters:  Note that these would be better as
# flags.
flights %>%
  filter((origin == 'LGA' & sched_dep_time > 2330) | # 1
           (month == 10 & day == 7 & dest == 'BQN') | # 2
           air_time > 550  # 3
         & dep_delay < 0 # 4
         )

# when you filter on flags, you don't need to write == TRUE
flights %>%
  filter(arrived_late == TRUE)

flights %>%
  mutate(arrived_late = arr_delay > 0) %>%
  filter(arrived_late)

flights %>%
  filter(!arrived_late) %>%
  select(arrived_late)

# any TAILNUMs that contain the letters 'N10'
flights %>%
  filter(grepl('N10', tailnum))

flights %>%
  filter(
    (arrived_late | departed_late) & origin == 'EWR'
  )

flights %>%
  filter(
    arrived_late | (departed_late & origin == 'EWR')
  )

flights %>%
  filter(str_detect(tailnum, 'N10'))

# FILTER ON MANY VARIABLES ------------------------------------------------

# remove any rows that contain any NAs in numeric columns
flights %>%
  filter(!if_any(.cols = where(is.numeric), # starts_with(...), c(arrival_delay, departure_delay...)
                 .fns = ~ is.na(.x))
         )

flights %>%
  filter(if_all(.cols = where(is.numeric), # starts_with(...), c(arrival_delay, departure_delay...)
                 .fns = ~ !is.na(.x))
  )

# keep rows that contain at least one NA!
View(flights %>%
  filter(if_any(.cols = where(is.numeric),
                 .fns = ~ is.na(.x))
  ))

# keep flights where all the columns containing the word 'time' are greater than
# 5 (for some reason)
flights %>%
  filter(if_all(.cols = contains('time'),
                .fns = ~ .x > 5)
  )

# FILTER WITHIN GROUPS ---------------------------------------------------------

# you can group before you filter - the filter will apply to each group
# separately.

# the single flight that arrived the latest
flights %>%
  filter(arr_delay == max(arr_delay, na.rm = T))

# the latest flight for each PLANE
flights %>%
  group_by(tailnum) %>%
  filter(arr_delay == max(arr_delay))

# SLICING -----------------------------------------------------------------

# Slicing functions are just a kind of filter

# top 5 rows
flights %>%
  slice_head(n = 5)

# top 5 rows per plane
flights %>%
  group_by(tailnum) %>%
  slice_head(n = 5)

# 10 flights that arrived earliest
flights %>%
  slice_min(arr_delay, n = 10)

# randomly select 10% of rows - useful if you have a lot of data and you want to
# test your code on something smaller!
flights %>%
  slice_sample(prop = 0.1)

sample_flights <- flights %>%
  slice_sample(n = 100)

# randomly select 1 row from each plane - even more useful if you want to test
# your code on a sample - so you're less likely to miss rare edge cases
flights %>%
  group_by(tailnum) %>%
  slice_sample(n = 1)

tailnumber_sample <- sample(flights$tailnum, 100)

# sample(data$trn, 100)

better_sample <- flights %>%
  filter(tailnum %in% tailnumber_sample)
  