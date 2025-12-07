library(shiny)
library(shinydashboard)
library(dplyr)      # Data manipulation
library(ggplot2)    # Plotting
library(tidyr)      # Tidy data
library(readr)      # Reading files
library(stringr)    # String tools
library(DBI)        # Database Interface
library(RPostgres)  # Postgres Driver
library(httr2)      # Web Requests (The new API tool)
library(jsonlite)   # JSON Parsing (The new API tool)

# Database Connection
db_connect <- function() {
  dbConnect(
    RPostgres::Postgres(),
    dbname = "research_db",
    host = "localhost",
    user = "research_user",
    password = "Sefunmi@8"  # <--- FIXED: Using the password directly for connection
  )
}