library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
library(stringr)
library(DBI)
library(RSQLite) # Changed from RPostgres to RSQLite
library(httr2)
library(jsonlite)

# Load Configuration (mostly for API keys now)
# We wrap this in tryCatch so it doesn't crash if config is missing
tryCatch({
  source("config.R", local = TRUE)
}, error = function(e) {
  # Defaults if config.R is missing
  APP_CONFIG <<- list(app_name = "Research Hub", version = "1.0.0")
})

# Logging Function
log_message <- function(level = "INFO", message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- sprintf("[%s] %s: %s\n", timestamp, level, message)
  cat(log_entry)
  
  log_dir <- "logs"
  if (!dir.exists(log_dir)) dir.create(log_dir)
  write(log_entry, file = file.path(log_dir, "app.log"), append = TRUE)
}

# --- SIMPLIFIED DATABASE CONNECTION (SQLite) ---
db_connect <- function() {
  tryCatch({
    # Connects to a file named 'research_data.db' in the app folder
    con <- dbConnect(RSQLite::SQLite(), "research_data.db")
    return(con)
  }, error = function(e) {
    log_message("ERROR", paste("Database connection failed:", e$message))
    return(NULL)
  })
}

# --- AUTO-INITIALIZE TABLES ---
# This runs once when the app starts to ensure tables exist
init_db <- function() {
  con <- db_connect()
  if (!is.null(con)) {
    # 1. Watch List Table
    dbExecute(con, "CREATE TABLE IF NOT EXISTS watch_list (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyword TEXT NOT NULL,
      source_type TEXT,
      is_active BOOLEAN DEFAULT 1,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )")
    
    # 2. Found Articles Table
    dbExecute(con, "CREATE TABLE IF NOT EXISTS found_articles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      url TEXT UNIQUE,
      published_date DATE,
      source TEXT,
      abstract TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )")
    
    dbDisconnect(con)
    log_message("INFO", "Database tables verified/created.")
  }
}

# Run initialization
init_db()

# --- HELPER FUNCTIONS ---

db_query_safe <- function(query, params = NULL) {
  con <- db_connect()
  if (is.null(con)) return(list(success = FALSE, error = "Connection failed"))
  
  tryCatch({
    if (!is.null(params)) {
      result <- dbGetQuery(con, query, params = params)
    } else {
      result <- dbGetQuery(con, query)
    }
    return(list(success = TRUE, data = result))
  }, error = function(e) {
    return(list(success = FALSE, error = e$message))
  }, finally = {
    dbDisconnect(con)
  })
}

db_execute_safe <- function(query, params = NULL) {
  con <- db_connect()
  if (is.null(con)) return(list(success = FALSE, error = "Connection failed"))
  
  tryCatch({
    if (!is.null(params)) {
      rows <- dbExecute(con, query, params = params)
    } else {
      rows <- dbExecute(con, query)
    }
    return(list(success = TRUE, rows = rows))
  }, error = function(e) {
    return(list(success = FALSE, error = e$message))
  }, finally = {
    dbDisconnect(con)
  })
}

validate_csv <- function(filepath) {
  tryCatch({
    data <- read.csv(filepath, nrows = 5)
    if (nrow(data) == 0) return(list(valid = FALSE, message = "File is empty"))
    if (ncol(data) == 0) return(list(valid = FALSE, message = "No columns found"))
    return(list(valid = TRUE, message = "File is valid", preview = data))
  }, error = function(e) {
    return(list(valid = FALSE, message = paste("Invalid CSV:", e$message)))
  })
}