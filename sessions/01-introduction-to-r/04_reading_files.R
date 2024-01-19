# Install necessary packages:
install.packages(c("readr", "readxl", "odbc", "DBI"))

# From file -----------------------------
# File -> Import Dataset
# csv: from Text (readr)
# Excel: From Excel...

library(readr)
penguins_summary <- read_csv("penguins_summary.csv")
View(iris_summary)


# From SQL --------------------------------

# Check what SQL drivers you have:
unique(odbc::odbcListDrivers()$name)

# Uncomment the relevant driver

con <- DBI::dbConnect(odbc::odbc(),
                      Driver = "ODBC Driver 17 for SQL Server",
                      # Driver = "SQL Server Native Client 11.0",
                      Server = "3DCPRI-PDB16\\ACSQLS",
                      database = "TAD_UserSpace",
                      Trusted_Connection = "Yes")

# Query ---------------

# If you have a query, copy it to your folder, add
#
# set nocount on
#
# to the top of the query, and make sure it returns one object.

sql_query <- readr::read_file("your_sql_query.sql")

lookups_post <- DBI::dbGetQuery(con, sql_query)

lookups_post

# Whole Table ------------------

lookups_post2 <- DBI::dbReadTable(
  conn = con,
  name = DBI::Id(database = "SWFC_Project", schema = "Lookups", table = "Post")
)

lookups_post2
