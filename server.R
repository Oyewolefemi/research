function(input, output, session) {
  
  # --- 1. SEARCH ENGINE FUNCTION ---
  fetch_papers <- function(keyword) {
    # Clean the keyword for the URL
    clean_query <- str_replace_all(keyword, " ", "+")
    # Semantic Scholar API URL
    url <- paste0("https://api.semanticscholar.org/graph/v1/paper/search?query=", clean_query, "&limit=5&fields=title,url,publicationDate,venue,abstract")
    
    print(paste("Searching for:", keyword))
    
    tryCatch({
      # Send Request
      req <- request(url)
      resp <- req_perform(req)
      data <- resp_body_json(resp)
      
      if (data$total == 0) return(FALSE)
      
      # Save results to Database
      con <- db_connect()
      for (paper in data$data) {
        # Check if exists
        exists <- dbGetQuery(con, paste0("SELECT id FROM found_articles WHERE url = '", paper$url, "'"))
        
        if (nrow(exists) == 0) {
           pub_date <- ifelse(is.null(paper$publicationDate), "2024-01-01", paper$publicationDate)
           # Insert into DB
           sql <- "INSERT INTO found_articles (title, url, published_date, source, abstract) VALUES ($1, $2, $3, $4, $5)"
           dbExecute(con, sql, params = list(
             paper$title,
             ifelse(is.null(paper$url), "#", paper$url),
             pub_date,
             "Semantic Scholar",
             ifelse(is.null(paper$abstract), "No abstract.", paper$abstract)
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

  # --- 2. BUTTON LOGIC ---
  observeEvent(input$add_topic_btn, {
    req(input$topic_input)
    
    # Show "Thinking" Message
    id <- showNotification("Agent is initializing...", type = "message", duration = NULL)
    
    # Save Topic to DB
    con <- db_connect()
    dbExecute(con, "INSERT INTO watch_list (keyword, source_type) VALUES ($1, $2)",
              params = list(input$topic_input, input$source_input))
    dbDisconnect(con)
    
    # Run Search
    showNotification("Scanning scientific databases...", id = id, type = "warning")
    success <- fetch_papers(input$topic_input)
    
    removeNotification(id)
    
    if(success) {
      showNotification("Found new papers! Feed updated.", type = "message")
      refresh_trigger(refresh_trigger() + 1) # Reload table
    } else {
      showNotification("Search complete. No new open-access papers found.", type = "warning")
    }
  })
  
  # --- 3. LIVE FEED LOGIC ---
  refresh_trigger <- reactiveVal(0)
  
  output$articles_table <- renderTable({
    refresh_trigger() # Listen for updates
    
    con <- db_connect()
    # Get real data from DB
    data <- dbGetQuery(con, "SELECT published_date, title, source FROM found_articles ORDER BY id DESC LIMIT 10")
    dbDisconnect(con)
    
    if(nrow(data) == 0) {
      return(data.frame(Status = "No data yet. Add a topic to start tracking."))
    }
    data %>% rename(Date = published_date, Title = title, Source = source)
  })

  # --- 4. DATA LAB PLOT ---
  output$data_plot <- renderPlot({
    plot(1:10, main = "Upload Data to Activate Lab")
  })
}