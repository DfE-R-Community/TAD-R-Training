
library(tidyverse)
library(tidylog)
library(nycflights13)

# PIVOTS -----------------------------------------------------------------------

# pivoting reshapes a data.frame by turning a column into multiple columns
# (pivot_wider) or by collapsing one or more columns into a single column
# (pivot_longer).

# our data is tidy right now - but sometimes we need it to be untidy
flights <- nycflights13::flights

# summarise average airtime from each origin to each destination:
flights_summarised <- flights %>%
  group_by(origin, dest) %>%
  summarise(mean_air_time = round(mean(air_time, na.rm = T), 0))

# not very easy to compare - what if we want a nice table?  We'd ideally want
# each origin airport to have its own column.  We want to spread the values from
# the mean_air_time column across three separate cols, using the values in origin
flights_summarised_wide <- flights_summarised %>%
  pivot_wider(
    names_from = origin,
    values_from = mean_air_time
  )

# note that this table is not very easy to do further work on!  what if we also
# wanted to find the destination airport with the most range?
flights_summarised <- flights_summarised %>%
  group_by(dest) %>%
  mutate(air_time_range = max(mean_air_time) - min(mean_air_time))

# because the values of air_time_range are the same for each value of 'dest',
# pivot automatically collapses them down.
flights_summarised_wide <- flights_summarised %>%
  pivot_wider(
    # where do the names for the new columns come from?
    names_from = origin, 
    # where do the values for the new cells come from?
    values_from = mean_air_time 
  )

# pivoting for graphs ----------------------------------------------------------

# ggplot works best with long data.  In a scatter graph, for example, each point
# on the graph would ideally be a row in your data table.

long_data <- flights %>%
  
  filter(tailnum == 'N3DUAA') %>%
  
  select(origin,
         dest,
         tailnum,
         time_hour,
         
         sched_dep_time,
         dep_time,
         
         sched_arr_time,
         arr_time) %>%
  # collapse the time variables
  pivot_longer(
    
    # which cols to collapse? note using tidyselect
    cols = ends_with('time'),
    
    # what is the name of the column to collapse the column names to?
    names_to = 'event',
    
    # what is the name of the column to collapse values to?
    values_to = 'time'
    
  ) %>%
  
  mutate(event = factor(event, 
                        levels = c('arr_time',
                                   'sched_arr_time',
                                   'dep_time',
                                   'sched_dep_time')))

# make a (maybe not very useful) graph showing times of flights
long_data %>%
  arrange(time_hour,
          event) %>%
  ggplot(aes(
    x = time,
    y = event,
    colour = dest,
    shape = event,
    group = time_hour
  )) +
  
  geom_path(colour = 'grey') +
  geom_point(size = 2)
  
# pivoting for exploratory data analysis ---------------------------------------

# challenge - we want to make histograms of all our numeric variables to look at
# their distributions on the same plot
flights %>%
  select(origin,
         where(is.numeric)) %>%
  
  pivot_longer(
    cols = c(-origin),
    names_to = 'var',
    values_to = 'value'
  ) %>%
  
  ggplot(aes(x = value,
             fill = origin)) +
  
  geom_histogram(colour = 'black',
                 bins = 40) +
  
  facet_wrap(
    ~ var,
    scales = 'free'
  )
