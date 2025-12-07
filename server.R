# server.R
function(input, output, session) {
  
  # 1. Logic for adding a new topic
  observeEvent(input$add_topic_btn, {
    req(input$topic_input)
    
    con <- db_connect()
    # Safe Insert (Prevents SQL Injection)
    dbExecute(con, "INSERT INTO watch_list (keyword, source_type) VALUES ($1, $2)",
              params = list(input$topic_input, input$source_input))
    dbDisconnect(con)
    
    showNotification("Topic added to Watcher!", type = "message")
  })
  
  # 2. Logic for displaying the feed (Mockup for now)
  output$articles_table <- renderTable({
    # In the real app, this will query the 'found_articles' table
    data.frame(
      Date = c("2024-01-01", "2024-01-02"),
      Title = c("Example Paper on Bamboo", "Global News Update"),
      Source = c("Semantic Scholar", "NewsAPI")
    )
  })
  
  # 3. Logic for Data Lab (Simple Plot)
  output$data_plot <- renderPlot({
    req(input$file_upload)
    # Placeholder: Just showing a blank chart until data is uploaded
    plot(1:10, main = "Data Analysis Preview")
  })
}