library(shiny)
library(shinydashboard)
library(dplyr)      # Data manipulation
library(ggplot2)    # Plotting
library(tidyr)      # Tidy data
library(readr)      # Reading files
library(stringr)    # String tools
library(DBI)        # Database Interface
library(RPostgres)  # Postgres Driver
library(httr2)      # Web Requests (New!)
library(jsonlite)   # JSON Parsing (New!)

# Database Connection
db_connect <- function() {
  dbConnect(
    RPostgres::Postgres(),
    dbname = "research_db",
    host = "localhost",
    user = "research_user",
    # OPTION A: If you want to be safe (Recommended)
    # Ensure your .Renviron file on the VPS has: DB_PASSWORD=Sefunmi@8
    password = Sys.getenv("Sefunmi@8")
    
    # OPTION B: If Option A is too hard, uncomment the line below (Less Secure)
    # password = "Sefunmi@8" 
  )
}