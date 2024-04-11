
library(tidyverse) # main package for data wrangling
library(tidylog) # very useful debugging package
library(janitor) # really handy for tidying up data
library(nycflights13) # our dataset

# DATA WRANGLING: the most important skill? ------------------------------------

# What does your data look like now?
# What do you need it to look like?
# What are the steps to get from A to B?

# TIDY DATA: the best place to aim for. ----------------------------------------

# VALUES, VARIABLES and OBSERVATIONS

# OBSERVATIONS: what is our data ABOUT?  what is one UNIT of the data?  In TAD's
# data, one unit is often a teacher in a given year, or a school in a given
# year.  In HEAD's data, one unit might be a student in a given year.  Or it
# could be a student in a period of study.

# VARIABLES: what types of information do we store about each OBSERVATION?  This
# could be a teacher's teaching reference number, age, gender or ethnicity - or
# it could be a student's course type, course start year or the university
# they're studying at.

# VALUES: what values are associated with these variables?  E.g. age = 39 years,
# gender = 'M', course start year = 2023.

# LAWS OF TIDY DATA
# 1. Each variable is a column; each column is a variable.
# 2. Each observation is a row; each row is an observation.
# 3. Each value is a cell; each cell is a single value.

flights <- nycflights13::flights

# this data is already tidy.

# What is the OBSERVATION?  Each row contains information about a single flight.
# All the information about that flight is contained on a single row.

# What are the variables?  year/month/day/time of departure, arrival and
# departure times, carrier, flight number, tail number, origin and destination
# airports, etc.

# values correspond to the variables as you'd expect.


# untidy data -------------------------------------------------------------

# some MESSY datasets we could make with this data:
dataset_a <- flights %>%
  count(origin, dest) %>%
  pivot_wider(names_from = origin,
              values_from = n)

# Why is this dataset NOT tidy?

# some other messy data:
dataset_b <- flights %>%
  mutate(id = paste0(year, month, day, flight)) %>%
  filter(tailnum == 'N14228') %>%
  select(id,
         dep_time,
         sched_dep_time,
         arr_time,
         sched_arr_time
         ) %>%
  
  pivot_longer(cols = contains('time'))

# Why is this dataset NOT tidy?

# The value of tidy data! ------------------------------------------------------

# what's so good about tidy data? It's built for R, and it's very flexible.

# these are VECTORISED operations - they operate on the columns of your table
# and do the same operation on every row.  These are very fast in R!