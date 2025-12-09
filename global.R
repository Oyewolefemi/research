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

# Load Configuration
source("config.R", local = TRUE)

# Logging Function
log_message <- function(level = "INFO", message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- sprintf("[%s] %s: %s\n", timestamp, level, message)
  
  # Print to console
  cat(log_entry)
  
  # Write to log file
  log_dir <- "logs"
  if (!dir.exists(log_dir)) dir.create(log_dir)
  write(log_entry, file = file.path(log_dir, "app.log"), append = TRUE)
}

# Database Connection Function with Error Handling
db_connect <- function() {
  tryCatch({
    con <- dbConnect(
      RPostgres::Postgres(),
      dbname = DB_CONFIG$dbname,
      host = DB_CONFIG$host,
      port = DB_CONFIG$port,
      user = DB_CONFIG$user,
      password = DB_CONFIG$password,
      connect_timeout = 10
    )
    
    # Test connection
    dbGetQuery(con, "SELECT 1 AS test")
    log_message("INFO", "Database connection established")
    return(con)
    
  }, error = function(e) {
    log_message("ERROR", paste("Database connection failed:", e$message))
    return(NULL)
  })
}

# Safe Database Query Function
db_query_safe <- function(query, params = NULL) {
  con <- db_connect()
  if (is.null(con)) {
    return(list(success = FALSE, data = NULL, error = "Connection failed"))
  }
  
  tryCatch({
    if (!is.null(params)) {
      result <- dbGetQuery(con, query, params = params)
    } else {
      result <- dbGetQuery(con, query)
    }
    
    return(list(success = TRUE, data = result, error = NULL))
    
  }, error = function(e) {
    log_message("ERROR", paste("Query failed:", e$message))
    return(list(success = FALSE, data = NULL, error = e$message))
    
  }, finally = {
    if (!is.null(con)) dbDisconnect(con)
  })
}

# Safe Database Execute Function
db_execute_safe <- function(query, params = NULL) {
  con <- db_connect()
  if (is.null(con)) {
    return(list(success = FALSE, error = "Connection failed"))
  }
  
  tryCatch({
    if (!is.null(params)) {
      rows_affected <- dbExecute(con, query, params = params)
    } else {
      rows_affected <- dbExecute(con, query)
    }
    
    log_message("INFO", paste("Query executed:", rows_affected, "rows affected"))
    return(list(success = TRUE, rows = rows_affected, error = NULL))
    
  }, error = function(e) {
    log_message("ERROR", paste("Execute failed:", e$message))
    return(list(success = FALSE, error = e$message))
    
  }, finally = {
    if (!is.null(con)) dbDisconnect(con)
  })
}

# Load Watchlist Function
get_watchlist <- function() {
  result <- db_query_safe("SELECT * FROM watch_list WHERE is_active = TRUE")
  
  if (result$success) {
    return(result$data)
  } else {
    return(data.frame())
  }
}

# Validate CSV Upload
validate_csv <- function(filepath) {
  tryCatch({
    data <- read.csv(filepath, nrows = 5)
    
    if (nrow(data) == 0) {
      return(list(valid = FALSE, message = "File is empty"))
    }
    
    if (ncol(data) == 0) {
      return(list(valid = FALSE, message = "No columns found"))
    }
    
    return(list(valid = TRUE, message = "File is valid", preview = data))
    
  }, error = function(e) {
    return(list(valid = FALSE, message = paste("Invalid CSV:", e$message)))
  })
}

# Initialize on Startup
log_message("INFO", paste("Application starting -", APP_CONFIG$app_name, "v", APP_CONFIG$version))