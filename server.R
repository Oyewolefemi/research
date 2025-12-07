function(input, output, session) {
  
  # --- 1. THE SEARCH ENGINE (API Logic) ---
  fetch_papers <- function(keyword) {
    # Prepare the URL for Semantic Scholar (Free Academic API)
    clean_query <- str_replace_all(keyword, " ", "+")
    url <- paste0("https://api.semanticscholar.org/graph/v1/paper/search?query=", clean_query, "&limit=5&fields=title,url,publicationDate,venue,abstract")
    
    print(paste("Searching for:", keyword))
    
    tryCatch({
      # Send the request to the internet
      req <- request(url)
      resp <- req_perform(req)
      data <- resp_body_json(resp)
      
      # If no results, stop
      if (data$total == 0) return(FALSE)
      
      # Connect to Database
      con <- db_connect()
      
      # Loop through each paper found and save it
      for (paper in data$data) {
        # Check if we already have this URL (Avoid Duplicates)
        exists <- dbGetQuery(con, paste0("SELECT id FROM found_articles WHERE url = '", paper$url, "'"))
        
        if (nrow(exists) == 0) {
           # Handle missing dates
           pub_date <- ifelse(is.null(paper$publicationDate), "2024-01-01", paper$publicationDate)
           # Handle missing abstracts
           abstract_text <- ifelse(is.null(paper$abstract), "No abstract available.", paper$abstract)
           
           # Insert into Database
           sql <- "INSERT INTO found_articles (title, url, published_date, source, abstract) VALUES ($1, $2, $3, $4, $5)"
           dbExecute(con, sql, params = list(
             paper$title,
             ifelse(is.null(paper$url), "#", paper$url),
             pub_date,
             "Semantic Scholar",
             abstract_text
           ))
        }
      }
      dbDisconnect(con)
      return(TRUE)
      
    }, error = function(e) {
      print(paste("Error searching:", e$message))
      return(FALSE)
    })
  }

  # --- 2. THE "START TRACKING" BUTTON ---
  observeEvent(input$add_topic_btn, {
    req(input$topic_input)
    
    # Notification: "We are starting"
    id <- showNotification("Initializing Research Agent...", type = "message", duration = NULL)
    
    # Save the Keyword to Watchlist
    con <- db_connect()
    dbExecute(con, "INSERT INTO watch_list (keyword, source_type) VALUES ($1, $2)",
              params = list(input$topic_input, input$source_input))
    dbDisconnect(con)
    
    # Run the Search Function
    showNotification("Scanning scientific databases...", id = id, type = "warning")
    success <- fetch_papers(input$topic_input)
    
    removeNotification(id)
    
    if(success) {
      showNotification("Success! New papers found.", type = "message")
      # Trigger the table to reload
      refresh_trigger(refresh_trigger() + 1)
    } else {
      showNotification("Search complete. No new open-access papers found.", type = "warning")
    }
  })
  
  # --- 3. THE LIVE FEED (Reads from Database) ---
  refresh_trigger <- reactiveVal(0)
  
  output$articles_table <- renderTable({
    refresh_trigger() # Listens for the button click
    
    con <- db_connect()
    # Pull the top 10 most recent papers
    data <- dbGetQuery(con, "SELECT published_date, title, source FROM found_articles ORDER BY id DESC LIMIT 10")
    dbDisconnect(con)
    
    if(nrow(data) == 0) {
      return(data.frame(Status = "No data yet. Add a topic to start tracking."))
    }
    
    # Make columns look nice
    data %>% 
      rename(Date = published_date, Title = title, Source = source)
  })

  # --- 4. DATA LAB PLOT (Placeholder) ---
  output$data_plot <- renderPlot({
    plot(1:10, main = "Upload Data to Activate Lab")
  })
}