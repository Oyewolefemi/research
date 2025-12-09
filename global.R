library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
library(stringr)
library(DBI)
library(RPostgres)
library(httr2)
library(jsonlite)

# Load Configuration (keeps other settings like host/user)
source("config.R", local = TRUE)

# Logging Function
log_message <- function(level = "INFO", message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- sprintf("[%s] %s: %s\n", timestamp, level, message)
  cat(log_entry) # Print to console
  
  log_dir <- "logs"
  if (!dir.exists(log_dir)) dir.create(log_dir)
  write(log_entry, file = file.path(log_dir, "app.log"), append = TRUE)
}

# --- UPDATED DATABASE CONNECTION ---
# Now accepts a password argument. Defaults to config if not provided.
db_connect <- function(password = NULL) {
  
  # Logic: Use the dynamic password if provided, otherwise fall back to config file
  pwd_to_use <- if (!is.null(password) && password != "") password else DB_CONFIG$password
  
  tryCatch({
    con <- dbConnect(
      RPostgres::Postgres(),
      dbname = DB_CONFIG$dbname,
      host = DB_CONFIG$host,
      port = DB_CONFIG$port,
      user = DB_CONFIG$user,
      password = pwd_to_use, # Uses the dynamic password
      connect_timeout = 10
    )
    
    # Test connection
    dbGetQuery(con, "SELECT 1 AS test")
    return(con)
    
  }, error = function(e) {
    log_message("ERROR", paste("Database connection failed:", e$message))
    return(NULL)
  })
}

# --- UPDATED HELPERS TO ACCEPT PASSWORD ---

db_query_safe <- function(query, params = NULL, password = NULL) {
  con <- db_connect(password) # Pass password here
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

db_execute_safe <- function(query, params = NULL, password = NULL) {
  con <- db_connect(password) # Pass password here
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

get_watchlist <- function(password = NULL) {
  result <- db_query_safe("SELECT * FROM watch_list WHERE is_active = TRUE", password = password)
  
  if (result$success) {
    return(result$data)
  } else {
    return(data.frame())
  }
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

log_message("INFO", paste("Application starting -", APP_CONFIG$app_name, "v", APP_CONFIG$version))