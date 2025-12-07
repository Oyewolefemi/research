library(shiny)
library(shinydashboard)
library(dplyr)      # Replaces 'tidyverse' to save memory
library(ggplot2)
library(tidyr)
library(readr)
library(stringr)
library(DBI)
library(RPostgres)
library(httr2)      # Essential for the Search Engine
library(jsonlite)   # Essential for the Search Engine

# Database Connection
db_connect <- function() {
  dbConnect(
    RPostgres::Postgres(),
    dbname = "research_db",
    host = "localhost",
    user = "research_user",
    password = "Sefunmi@8"  # <--- FIXED: Using the password directly
  )
}

# Load Watchlist
get_watchlist <- function() {
  con <- db_connect()
  on.exit(dbDisconnect(con))
  dbGetQuery(con, "SELECT * FROM watch_list WHERE is_active = TRUE")
}