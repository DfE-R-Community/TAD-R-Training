
library(tidyverse)

flights <- nycflights13::flights


# DISTINCT ----------------------------------------------------------------

# Useful for getting rid of duplicates in your data, but BE CAREFUL.

# each unique combination of the above, dropping other columns.  SAFE.
flights %>%
  distinct(tailnum, origin, dest)

# DANGEROUS - which duplicates are you keeping?  
flights %>%
  distinct(tailnum, .keep_all = TRUE) %>%
  filter(tailnum == 'N14228')

# if the rows are in a different order, I get a different result
flights %>%
  arrange(arr_time) %>%
  distinct(tailnum, .keep_all = TRUE) %>%
  filter(tailnum == 'N14228')


# PULL --------------------------------------------------------------------

# what if you want to get a specific number out of a dataframe?  You can use
# PULL
when_did_my_flight_leave <- flights %>%
  filter(tailnum == 'N14228', month == 3, day == 30) %>%
  pull(dep_time)

print(paste0('my flight left at ', when_did_my_flight_leave))


# STRINGR -----------------------------------------------------------------

# StringR is a package in the tidyverse that provides many tools for working
# with strings

# replace one pattern with another
flights %>%
  mutate(origin = str_replace(origin, 'EWR', 'Newark Liberty International Airport'))

# remove a pattern
flights %>%
  mutate(origin = str_remove(origin, 'EWR'))

# extract a substring using position
flights %>%
  mutate(tailnum_first_chars = substr(tailnum, 1, 2)) %>%
  select(tailnum, tailnum_first_chars)

# check if a pattern exists (similar to grepl)
flights %>%
  mutate(leaving_from_newark = str_detect(origin, 'EWR')) %>%
  select(origin, leaving_from_newark)

# StringR uses a powerful tool called regex, which lets you match complicated
# patterns like 'everything after the underscore' or 'only the numbers from this
# string' and similar
flights %>%
  mutate(numbers_in_tailnum = str_extract(tailnum, '\\d+')) %>%
  select(tailnum, numbers_in_tailnum)

# Unless you do a lot of this, not worth learning.  Use StackExchange and/or
# copilot.  Make sure you check the results either way

# Creating data frames ------------------------------------------------------------------

tibble <- tibble(
  airport = c('NY', 'LA', 'MI'),
  flights = c('5', '15', '23')
)

every_destination_to_every_origin <- expand_grid(
  origin = unique(flights$origin),
  dest = unique(flights$dest)
)

