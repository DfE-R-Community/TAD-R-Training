

# MUTATE ------------------------------------------------------------------

# Mutate is used to add new columns to your data.  Mutate applies the same rule
# to each row of your dataset, using the column names that you provided.

# adding simple columns --------------------------------------------------------

# Let's add some columns
flights <- flights %>%
  
  # some simple variables
  mutate(air_time_hours = air_time / 60,
        flight_speed_mph = distance / air_time_hours,
        total_delay = arr_delay + dep_delay,
        late_percentage = total_delay / air_time,
        test = 'TEST COLUMN PLEASE IGNORE')


# adding LOGICAL FLAGS ---------------------------------------------------------


flights <- flights %>%
  
  mutate(departed_late = dep_delay > 0,
        arrived_late = arr_delay > 0,
        
        departed_and_arrived_late = departed_late & arrived_late,
        departed_or_arrived_late = departed_late | arrived_late,
        
        did_not_depart = is.na(dep_time))

# manually checking data!
flights %>%
  count(departed_late)

flights %>%
  count(departed_late,
        arrived_late,
        departed_and_arrived_late,
        departed_or_arrived_late,
        did_not_depart)

# check if any flights meet the AND condition but not the OR condition!
if ( 
  nrow(flights %>%
    filter(departed_and_arrived_late &
           !departed_or_arrived_late)) != 0
) {
  
  stop('Something has gone wrong!')
  
}

# IF_ELSE and CASE_WHEN ---------------------------------------------------

# carriers that have compensation plans
compensation_carriers <- nycflights13::airlines$carrier[1:5]

# IF ELSE and CASE WHEN are very useful tools, but they are commonly abused!
# It's easy to write if_else statements that are very hard to follow.  I think
# excel is the source for these bad habits.

# IF ELSE seems to struggle with dates.  You may need to reformat your dates
# before or after, or you can try using the p_type argument.  

flights <- flights %>%
  
  # you can use if_else to do simple logical tests.  Note: you could use a
  # logical flag for this - and I would recommend it if you only want a TRUE or
  # FALSE.
  mutate(is_it_late = if_else(condition = dep_delay > 0, 
                              true = 'LATE!', 
                              false = 'NOT LATE',
                              missing = 'DATA MISSING'),
         
         # COMPLEX CONDITIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         
         # if you want to make a complex condition, make flags and test those -
         # it's easier to check each prong is working properly
         compensation_flag = if_else(
           origin != 'LGA' & (dep_delay > 30 | arr_delay > 45) & carrier %in% compensation_carriers,
           'due compensation',
           'not due compensation'
         )) %>%
  
  mutate(
         
         # break each 'prong' into a separate logical flag
         origin_compensates = origin != 'LGA',
         carrier_compensates = carrier %in% compensation_carriers,
         departure_over_comp_threshold = dep_delay > 30 | is.na(dep_delay),
         arrival_over_comp_threshold = arr_delay > 45 | is.na(arr_delay),
         
         # then combine them
         compensation_flag_new = if_else(origin_compensates & 
                                           carrier_compensates & 
                                           (departure_over_comp_threshold | arrival_over_comp_threshold),
                                         
                                         'due compensation',
                                         'not due compensation')) %>%
  
  mutate(
         
         # NESTED IF ELSE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         
         # You may at times be tempted to put an IF ELSE inside another IF ELSE:
         
         # imagine we want to create a variable that categorises flights by what
         # kind of lateness they experienced.
    
         late_type = if_else(dep_delay <= 0 & arr_delay <= 0,
                             # if there was no departure or arrival delay, then
                             # NOT LATE
                             'NOT LATE',
                             # otherwise...
                             if_else(dep_delay > 0 & arr_delay <= 0,
                                     'LEFT LATE AND ARRIVED EARLY',
                                     
                                     if_else(dep_delay > 0 & arr_delay > 0,
                                             'PLEASE JUST LET IT END',
                                             '...HELP...')
                                     )
                             ),
         
         # What's the alternative?
         late_type_case_when = case_when(
           is.na(arr_time) ~ 'DID NOT ARRIVE',
           dep_delay <= 0 & arr_delay <= 0 ~ 'LEFT AND ARRIVED ON TIME',
           dep_delay > 0 & arr_delay <= 0 ~ 'LEFT LATE, ARRIVED ON TIME',
           dep_delay > 0 & arr_delay > 0 ~ 'LEFT LATE AND ARRIVED LATE',
           # ...
           TRUE ~ 'DUNNO'
         ),
         
         # note we can reuse our flags
         late_type_case_when = case_when(
           did_not_depart ~ 'DID NOT ARRIVE',
           !departed_late & !arrived_late ~ 'LEFT AND ARRIVED ON TIME',
           departed_late & !arrived_late ~ 'LEFT LATE, ARRIVED ON TIME',
           !departed_late & arrived_late ~ 'LEFT ON TIME, ARRIVED ON LATE',
           departed_late & arrived_late ~ 'LEFT LATE AND ARRIVED LATE'
         ),
         
         # when should you just have driven?
         approx_drive_time = distance / 60,
         
         should_i_have_driven_there = case_when(
           approx_drive_time > air_time_hours * 2 ~ 'No, air was much faster',
           approx_drive_time > air_time_hours * 1.5 ~ 'No, air was somewhat faster',
           approx_drive_time > air_time_hours * 1.25 ~ 'No, air was slightly faster',
           approx_drive_time > air_time_hours * 0.75 ~ 'Not much in it',
           TRUE ~ 'You should have just driven'
         ),
         
         drive_to_fly_ratio = approx_drive_time / air_time_hours
         
         )

# DATES in focus ---------------------------------------------------------------

# You might thing DATES are just a delicious dried fruit, but they're actually
# the most annoying data type in R
flights <- flights %>%
        
  mutate(      
        # The following code combines the day, month and year variables into a
        # CHARACTER TYPE variable
        dmy = paste0(day, "/", month, "-", year),

        
        # dates can be written in lots of ways - for R to interpret something as
        # a date, we need to provide information about the date FORMAT.  You can
        # look these symbols up online.
        
        # %d = day as a two-digit number e.g. 01, 25, 30
        # %m = month as a two-digit number e.g. 01, 05, 10
        # %Y = year as a four-digit number e.g. 2024, 1904, 1066
        
        date = as.Date(dmy, format = '%d/%m-%Y')
        
        # there are other codes for e.g. abbreviated month names, days of the
        # week, date + time codes, etc.  Note that you might have to do annoying
        # things like change 'Sept' into 'Sep' if you're working with data that
        # has been mangled by excel
        )


# Binning variables -------------------------------------------------------------

# NTILE splits your variables into N equal-sized groups
flights <- flights %>%
  mutate(delay_decile = ntile(dep_delay, 10),
         delay_bins = cut(dep_delay, breaks = c(-100, -50, -25, 0, 25, 50, 100, 500)),
         delay_bis_seq = cut(dep_delay, breaks = seq(-500, 500, 100))
         )


# Factor variables -------------------------------------------------------------

flights <- flights %>%
  mutate(carrier = factor(carrier),
         late_type_case_when = factor(late_type_case_when,
                                      levels = c('...')))

# ACROSS -----------------------------------------------------------------------

# sometimes, you will want to do the same thing to many variables.  For example,
# we might want to round many variables

flights <- flights %>%
  mutate(
    across(.cols = c(arr_delay, dep_delay, arr_time, dep_time), # COLS is a list of your columns
           .fns = ~ round(.x, digits = -1)) # .x represents each column in .cols
  )

flights <- flights %>%
  mutate(
    across(.cols = c(arr_delay, dep_delay, arr_time, dep_time), # COLS is a list of your columns
           .fns = ~ .x / 60,
           .names = '{.col}_hours') # .x represents each column in .cols
  )

# LEAD / LAG -------------------------------------------------------------------

# LEAD and LAG mean 'look x rows forward/backward in the data'

small_flights <- flights %>%
  filter(tailnum == 'N668DN',
         !did_not_depart)

small_flights <- small_flights %>%
  # sort by date first!
  arrange(date) %>%
  mutate(time_between_flights = date - lag(date))

# note that LEAD and LAG do not understand the concept of time.  if you have
# yearly data but with some years missing, LEAD and LAG will not account for
# this.  They are also sensitive to the order of the rows!
  
# CUMULATIVE VARS ---------------------------------------------------------

small_flights <- small_flights %>%
  arrange(date) %>%
  mutate(cumulative_airtime = cumsum(air_time_hours),
         test_2 = cumprod(air_time_hours))

plot(small_flights$cumulative_airtime,
     small_flights$total_delay)

