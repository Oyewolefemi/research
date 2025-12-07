library(shiny)
library(shinydashboard)
library(dplyr)      # Replacement for tidyverse
library(ggplot2)
library(tidyr)
library(readr)
library(stringr)
library(DBI)
library(RPostgres)
library(httr2)      # Required for the Search Engine
library(jsonlite)   # Required for the Search Engine

# Database Connection
db_connect <- function() {
  dbConnect(
    RPostgres::Postgres(),
    dbname = "research_db",
    host = "localhost",
    user = "research_user",
    password = "Sefunmi@8"  # <--- DIRECT PASSWORD (No Sys.getenv)
  )
}

# Load Watchlist
get_watchlist <- function() {
  con <- db_connect()
  on.exit(dbDisconnect(con))
  dbGetQuery(con, "SELECT * FROM watch_list WHERE is_active = TRUE")
}