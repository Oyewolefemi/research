# global.R
library(shiny)
library(shinydashboard)
library(tidyverse)
library(DBI)
library(RPostgres)

# Database Connection (Reads secrets from the Server Environment)
# We do not hardcode passwords here!
db_connect <- function() {
  dbConnect(
    RPostgres::Postgres(),
    dbname = "research_db",
    host = "localhost", # On VPS this is localhost
    user = "research_user",
    password = Sys.getenv("Sefunmi@8") # Magic: Reads hidden password
  )
}

# Load Watchlist (Helper function)
get_watchlist <- function() {
  con <- db_connect()
  on.exit(dbDisconnect(con))
  dbGetQuery(con, "SELECT * FROM watch_list WHERE is_active = TRUE")
}