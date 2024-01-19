# R is scripting language
# much more interactive than SQL, slightly less interactive than Excel

# Generally you should run each line as you write it,
# to make sure it works as you expect.

# Comments -----------------------------------

# Comments begin with a number sign/hash/hashtag/pound symbol/#
# R doesn't run them

# You've heard the advice "always comment your code"

# Comment your code, but aim to only comment on the _why_.
# The _how_ should be self-explanatory in well-written code.

# If it isn't self-explanatory you should try to refactor it.

# (i.e. don't do this):

# Read in csv
data <- read_csv("file.csv")

# Instead, refactor to make clearer and don't have a comment:

transaction_data_2013 <- read_csv("transaction_data_2013.csv")

# Few reasons:
# * Make it easier for QA analyst to catch bugs
# have them actually read the code
# * DRY principle 

# Maths -------------------------
# Maths works similar to excel.
5 + 5
3 / 5

# Variables
pi * 6

exp(1)

# Variables ----------------------------------
# The things above run and dissapear
# To save things, use: `<-` or `=`.
# Prefer <-
x <- 5
y = 4

# If in doubt consult style guide:
# https://style.tidyverse.org/

# note: = not the same as ==
x == y

x = y


# Briefly on names....
# Use snake_case or camelCase and stick with it.
# Give your variables informative names

# Bad:
x <- 1.02

# Good:
inflation_uplift <- 1.02

# Same goes for file names: use consistent names (snake_case is most common)
# Add a prefix if there is an order:
# 01_data_download.R
# 02_data_clean.R
# 03_analysis.R

# Functions ------------------------
# Similar to excel -- you call them with open brackets
rnorm

# Use tab complete to learn more about it
rnorm()

rnorm(n = 100, mean = 0, sd = 1)
rnorm(100, 0, 1)

# Give names to non-obvious arguments.
# The above might be clear but this isn't:
rnorm(100, 1000, 100)

# You'll learn over time what's obvious and what isn't.
# In this example mean and sd aren't obvious.
# but in all dplyr function data is the first argument, so you don't
# have to write "data = penguins", every time.

# Not all functions have required arguments
# once again, `?` is useful
ls()

?ls

# Data Types/Classes ------------

# Just like in excel

# Atomic Types --------------------------

# Atomic because they make up all the other types

# There's many others (Date/time, complex etc) but the 4 core ones are:
# * Numeric (integer/double)
# * Character
# * Factor
# * Boolean/Logical (True False)

# Numerics
class(5L)
class(5.0)

# Strings/Characters
class("5")
class("foo")

# Maths makes sense with numerics
5 / 3

# some maths works but doesn't make sense with characters
"10" > "2"


# Factors
# Integers and Characters put together
# Useful for 'multiple choice' like:
school_status <- c("LA Maintained", "Non-LA Maintained")
school_status <- factor(school_status)

# 3 main uses for factors:
# * Saves memory (behind the scenes it's a number)
# * Logic (Graduate > Undergrad)
# * Plotting:

ggplot() +
  geom_point(aes(x = 1:100, y = rnorm(100), color = rep(1:4, 25)))

ggplot() +
  geom_point(aes(x = 1:100, y = rnorm(100), color = rep(1:4, 25) |> factor()))

# This uses an ordered factor:

teachers <- c("M1", "M4", "M2")

teachers_factor <- ordered(
  teachers,
  levels = c("M1", "M2", "M3", "M4")
)

teachers_factor[3] > teachers_factor[2]

# square brackets can be used to select elements
c(10, 20, 30)[3]

# double square brackets _extract_ an element
# single square brackets filter it to just that one
l <- list(1, 10)
class(l[1])
class(l[[1]])

# same for data.frames
iris[1]
iris[[1]]

# Boolean -- just like excel
TRUE
FALSE

# Logic
5 == 5 # is equal  (not like excel, where it's `=`)
5 != 5 # is not equal (<> in excel)
TRUE | FALSE # | = OR
T & F # & = AND
# TRUE and FALSE can be abbreviated to T and F but not recommended.
!TRUE # ! = NOT
2 > 5
5 <= 10


# Coercion -- use `as.foo`
as.numeric(TRUE) # Explicit
as.numeric(FALSE) # Explicit

TRUE + TRUE # Implicit

# Useful sometimes:
teacher_retained <- c(TRUE, TRUE, FALSE, FALSE, FALSE, FALSE)
mean(teacher_retained)


"5" + "8"
as.numeric("5") + as.numeric("3")

as.numeric
as.character
as.Date
as.logical # use tab-complete
as.

# Vectors -------------------------

# All atomic stuff is a vector -- no scalars
identical(1, c(1))

# c() is used to make a vector with multiple elements
# of the _same_ type
c(1, 10, 100)

# will work but dangerous
c(1, "foo", "bar")

# use a list if you need to have different types
list_with_stuff <- list(1, "foo", "bar", list("foo", "baz"))

# sapply = for loop -- we'll cover it another time
sapply(list_with_stuff, class)

# R "recycles" vectors
economic_data <- 1:3 # same as c(1,2,3), or seq(1, 3, by = 1)
inflation_uplift <- 1.02

economic_data * inflation_uplift # Length 3 * Length 1
# equivalent to doing $ $ around the length 1 vector

length(economic_data)
length(inflation_uplift)

yearly_inflation_uplift <- c(1.02, 1.07, 1.20)

economic_data * yearly_inflation_uplift

# You want to always use vectors of the same length,
# or vectors of length 1.
# ... just like in Excel

# This works but don't do it:

1:3 * c(1.02, 1000) # Will work with warning message
c(1:10) + c(10, 100) # Will works without warning

length(c(1:10))
length(c(10, 100))

# Data Frames -----------------------------

# Rectangular data, made up of atomic elements
# Think columns and rows.
penguins <- palmerpenguins::penguins

# "Explore your data" functions

class(penguins) # Type of object

names(penguins) # Names of data.frame

str(penguins) # Structure

summary(penguins)

# Working with data.frames is  easier with the tidyverse
# install.packages("tidyverse") # Only have to run this once

library(tidyverse) # Put in every script where you want to use it

library(MASS)

select

plyr

conflicted::conflict_prefer("select", dplyr)
conflicted::conflict_prefer_all("tidyverse", "MASS")

# Tidyverse is a collection of packages, most importantly dplyr.

# For historical reasons, the only sensible ways to use R are with tidyverse
# (or if you need speed) data.table
# In general, avoid using base R for most things unless you're
# writing packages.

# Pipes ---------------

# %>% = pipe
# (also |>)
# (they're slightly different)
# It's used to pass the top thing "into" the next.
# So instead of
identical(mean(sqrt(exp(c(5,10))), na.rm = TRUE), 3)

# You can write
c(5,10) %>%
  exp() %>%
  sqrt() %>%
  mean(na.rm = TRUE) %>%
  identical(3, y = .) # Same as identical(5)

# Weird pipes

# %T>%
# %$%
# %<>%


# I don't use them, I find they're harder to read.
# Very little extra payoff in this case,
# but not always

# |> and %>% are the main ones.


# Sometimes nice functions are very useful.

# data.table::cube

library(data.table)
penguinsdt <- as.data.table(penguins)

ees_summary <- data.table::cube(
  x = penguinsdt,
  j = list("column_mean" = mean(bill_length_mm, na.rm = TRUE)),
  by = c("species", "island", "year")
)

ees_summary %>%
  dplyr::mutate(across(
    c("species", "island", "year"),
    ~ .x |> as.character() |> tidyr::replace_na("All")
  ))

# Refactor example: DRY


# Using the tidyverse ---------------------

# Most of the time your data will be a table
# in R this is called a data.frame, or tibble

# ... just like in Excel

# 6 Basic Operations for data.frames
# 1. select - Selecting columns
# 2. filter - Filtering rows
# 3. mutate - Creating new columns
# 4. arrange - Sort by column
# 5. summarise - summarises into new table
# 6. group_by - groups the previous operations.

conflicted::conflicts_prefer(dplyr::select)

# Selecting columns
penguins %>%
  dplyr::select(species, bill_length_mm)

# I use this one the least, no reason to -- unless you're saving on memory.
conflicted::conflicts_prefer(dplyr::filter)

# Filtering values
penguins_filtered <- penguins %>%
  filter(bill_length_mm > 50)

# tidylog is useful sometimes
penguins_filtered <- penguins %>%
  tidylog::filter(bill_length_mm > 50)

# but don't rely on it for QA -- use proper assertions
# Also, comment _why_ this stopifnot is important
stopifnot(nrow(penguins_filtered) > 60)

# Multiple conditions can be separated by commas
# , which implicitly mean &
penguins_filtered2 <- penguins %>%
  filter(bill_length_mm > 7, species == "Gentoo") # Note I use `==` and not `=`

# Creating new columns
penguins <- penguins %>%
  mutate(bill_ratio = bill_length_mm * 5)

# Sorting by column
# I use this rarely, unless working with leads and lags of panel data.
penguins %>%
  arrange(bill_length_mm) # arrange(desc(column)) for descending

# Summarise -- "each group to one row"
penguins %>%
  summarise(mean_sepal_length = mean(bill_length_mm))

# R is strict about NA's (unlike Excel)
mean(c(1, 2, NA))

# In practice, you'll want to either filter NA's out with
# filter(!is.na(bill_length_mm))
# or more commonly add
# na.rm = TRUE
# to some function

mean(c(1, 2, NA), na.rm = TRUE)

# WARNING: usually best to wait until the last moment to remove NA's.
# SQL download and `filter(across(everything()), ~ !is.na(.x))`

penguins %>%
  summarise(mean_sepal_length = mean(bill_length_mm, na.rm = TRUE))

# Grouped Summaries
penguins %>%
  group_by(species) %>%
  summarise(mean_bill_length = mean(bill_length_mm, na.rm = TRUE))

# with tidylog
penguins %>%
  tidylog::group_by(species, island) %>%
  tidylog::summarise(mean_sepal_length = mean(bill_length_mm, na.rm = TRUE))


# group_by works with all the other functions too
penguins2 <- penguins %>%
  group_by(species) %>%
  mutate(mean_sepal_length = mean(bill_length_mm, na.rm = TRUE))

# Note that you need an explicit `ungroup` after group_by mutate
penguins2 %>%
  count(mean_sepal_length)
  

# Some more advanced filters
penguins %>%
  group_by(species) %>%
  filter(rank(desc(bill_length_mm)) == 1) %>%

# rank function
some_numbers <- c(1, 65, 23, 3939, 0, -3)
desc(rank(some_numbers))

# You can combine all of them together easily
# most of your code will look more like this
penguins_summary <- penguins %>%
  filter(species %in% c("Adelie", "Gentoo")) %>%
  group_by(species) %>%
  summarise(
    mean_sepal_length = mean(bill_length_mm, na.rm = TRUE),
    sd_sepal_length = sd(bill_length_mm, na.rm = TRUE),
    max_sepal_length = max(bill_length_mm, na.rm = TRUE),
    min_sepal_length = min(bill_length_mm, na.rm = TRUE)
  ) %>%
  arrange(desc(mean_sepal_length))


# %in% operator
"foo" %in% c("random", "words", "foo")

c("random", "words", "foo") %in% "foo"

c("random", "words", "foo") %in% c("foo", "bar")

c("foo", "bar") %in% c("random", "words", "foo")

penguins %>%
  count(species) %>%
  filter(species %in% "Gentoo")

# Saving ------------------------------
# Finally, you can save your results into a csv or xlsx.
write_csv(penguins_summary, "penguins_summary.csv")

# Note - R will make the file, but will NOT make the folder
# if you're trying to create a new folder you have to create the folder yourself

# You can also use
# dir.create("outputs")

# install.packages("writexl")

writexl::write_xlsx(penguins_summary, "penguins_summary.xlsx")

# Packages ---------------
# You can access package functions using either

# package::function()

# or

# library(package)

writexl::write_xlsx()

library(writexl)
write_xlsx()

# General workflow for using packages
# 1. Find one you want -  eg. Google "SPSS data R"
# you'll probably find `haven`

# 2. Install
# install.packages("haven")

# 3. Either library call or :: notation
# haven::read_spss(...)

# If you use something only once, might be fine to use ::
# Otherwise probably better to call it with library
# Ignore this if you're writing a package

# Folder structure and organisation -------------------
# In excel there's no difference between:
# 1. Data
# 2. Analysis
# 3. Output

# In R you should store them separately
# 1. Data - in `data/` or sql code in `data-raw/` or `sql/`
# 2. Analysis - in R/ or scripts/
# 3. Output - in `output/` or `charts/`

# You should be able to delete everything in your output folder,
# rerun your analysis, and get the same results.

# Your analysis script + raw data become the "source of truth".
