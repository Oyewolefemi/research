function(input, output, session) {
  
  # --- 1. AUTHENTICATION LOGIC ---
  # Reactive value to store the password once logged in
  auth_pass <- reactiveVal(NULL)
  
  # Show Login Modal on Startup
  showModal(modalDialog(
    title = "System Login",
    passwordInput("startup_password", "Enter Database Password", placeholder = "Input password..."),
    footer = tagList(
      actionButton("login_btn", "Connect Securely", class = "btn-success")
    ),
    easyClose = FALSE, # User cannot close without logging in
    fade = FALSE
  ))
  
  # Verify Password when clicked
  observeEvent(input$login_btn, {
    req(input$startup_password)
    
    # Attempt connection with provided password
    test_con <- db_connect(password = input$startup_password)
    
    if (!is.null(test_con)) {
      # Success! Save password and remove modal
      dbDisconnect(test_con)
      auth_pass(input$startup_password)
      removeModal()
      showNotification("Authentication successful. System online.", type = "message")
    } else {
      # Failure
      showNotification("Connection failed. Check password.", type = "error")
    }
  })
  
  # --- 2. SEARCH ENGINE FUNCTION ---
  fetch_papers <- function(keyword, db_password) {
    clean_query <- str_replace_all(keyword, " ", "+")
    url <- paste0("https://api.semanticscholar.org/graph/v1/paper/search?query=", clean_query, "&limit=5&fields=title,url,publicationDate,venue,abstract")
    
    print(paste("Searching for:", keyword))
    
    tryCatch({
      req <- request(url)
      resp <- req_perform(req)
      data <- resp_body_json(resp)
      
      if (data$total == 0) return(FALSE)
      
      # Use dynamic password for connection
      con <- db_connect(password = db_password)
      
      if(is.null(con)) return(FALSE)
      
      for (paper in data$data) {
        exists <- dbGetQuery(con, paste0("SELECT id FROM found_articles WHERE url = '", paper$url, "'"))
        
        if (nrow(exists) == 0) {
           pub_date <- ifelse(is.null(paper$publicationDate), "2024-01-01", paper$publicationDate)
           
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

  # --- 3. BUTTON LOGIC ---
  observeEvent(input$add_topic_btn, {
    req(input$topic_input)
    req(auth_pass()) # Wait for login
    
    id <- showNotification("Research Agent initializing...", type = "message", duration = NULL)
    
    # Save Topic
    con <- db_connect(password = auth_pass())
    dbExecute(con, "INSERT INTO watch_list (keyword, source_type) VALUES ($1, $2)",
              params = list(input$topic_input, input$source_input))
    dbDisconnect(con)
    
    # Run Search
    showNotification("Scanning scientific databases...", id = id, type = "warning")
    success <- fetch_papers(input$topic_input, db_password = auth_pass())
    removeNotification(id)
    
    if(success) {
      showNotification("Found new papers! Feed updated.", type = "message")
      refresh_trigger(refresh_trigger() + 1)
    } else {
      showNotification("Search complete. No new open-access papers found.", type = "warning")
    }
  })
  
  # --- 4. LIVE FEED LOGIC ---
  refresh_trigger <- reactiveVal(0)
  
  output$articles_table <- renderTable({
    req(auth_pass())
    refresh_trigger()
    
    con <- db_connect(password = auth_pass())
    
    if(is.null(con)) return(data.frame(Status = "Database connection lost."))
    
    data <- dbGetQuery(con, "SELECT published_date, title, source FROM found_articles ORDER BY id DESC LIMIT 10")
    dbDisconnect(con)
    
    if(nrow(data) == 0) {
      return(data.frame(Status = "No data yet. Add a topic to start tracking."))
    }
    data %>% rename(Date = published_date, Title = title, Source = source)
  })

  # --- 5. DATA LAB PLOT ---
  output$data_plot <- renderPlot({
    plot(1:10, main = "Upload Data to Activate Lab")
  })
  
  # --- 6. DASHBOARD WIDGETS (MISSING PIECES RESTORED) ---
  
  # Helper to get counts safely
  get_count <- function(table) {
    req(auth_pass())
    res <- db_query_safe(paste0("SELECT COUNT(*) as count FROM ", table), password = auth_pass())
    if(res$success) return(res$data$count) else return(0)
  }

  output$total_topics <- renderValueBox({
    valueBox(get_count("watch_list"), "Active Topics", icon = icon("list"), color = "aqua")
  })
  
  output$total_articles <- renderValueBox({
    valueBox(get_count("found_articles"), "Articles Found", icon = icon("book"), color = "green")
  })
  
  output$data_uploads <- renderValueBox({
    # Placeholder
    valueBox(0, "Data Uploads", icon = icon("upload"), color = "yellow")
  })
  
  output$system_health <- renderValueBox({
    req(auth_pass()) # Only show if connected
    valueBox("Online", "System Status", icon = icon("heartbeat"), color = "green")
  })
  
  output$recent_activity <- renderTable({
    req(auth_pass())
    con <- db_connect(password = auth_pass())
    if(is.null(con)) return(NULL)
    
    data <- dbGetQuery(con, "SELECT title, source, published_date FROM found_articles ORDER BY id DESC LIMIT 5")
    dbDisconnect(con)
    data
  })
}