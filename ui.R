# ui.R - User Interface

dashboardPage(
  skin = "black",
  
  dashboardHeader(
    title = span(icon("microscope"), "Research Hub"),
    titleWidth = 250
  ),
  
  dashboardSidebar(
    width = 250,
    sidebarMenu(
      id = "sidebar",
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Trend Watcher", tabName = "trends", icon = icon("eye")),
      menuItem("Data Lab", tabName = "datalab", icon = icon("flask")),
      menuItem("Settings", tabName = "settings", icon = icon("cogs")),
      menuItem("System Status", tabName = "status", icon = icon("heartbeat"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #f4f4f4; }
        .box { border-radius: 5px; }
        .btn-success { background-color: #28a745; border-color: #28a745; }
        .small-box { border-radius: 5px; }
      "))
    ),
    
    tabItems(
      # --- DASHBOARD TAB ---
      tabItem(tabName = "dashboard",
        h2("Research Hub Dashboard"),
        fluidRow(
          valueBoxOutput("total_topics", width = 3),
          valueBoxOutput("total_articles", width = 3),
          valueBoxOutput("data_uploads", width = 3),
          valueBoxOutput("system_health", width = 3)
        ),
        fluidRow(
          box(
            title = "Recent Activity", status = "primary", solidHeader = TRUE, width = 12,
            tableOutput("recent_activity")
          )
        )
      ),
      
      # --- TREND WATCHER TAB ---
      tabItem(tabName = "trends",
        fluidRow(
          box(
            title = "New Search Topic", status = "primary", solidHeader = TRUE, width = 4,
            textInput("topic_input", "What should we track?", placeholder = "e.g., Bamboo Fiber"),
            selectInput("source_input", "Source", 
                       choices = c("Scientific Papers", "Global News")),
            actionButton("add_topic_btn", "Start Tracking", class = "btn-success", width = "100%")
          ),
          
          box(
            title = "Active Watchlist", status = "info", solidHeader = TRUE, width = 8,
            tableOutput("watchlist_table")
          )
        ),
        
        fluidRow(
          box(
            title = "Live Intelligence Feed", status = "primary", solidHeader = TRUE, width = 12,
            p("Recent updates found by the system:"),
            tableOutput("articles_table")
          )
        )
      ),
      
      # --- DATA LAB TAB ---
      tabItem(tabName = "datalab",
        fluidRow(
          box(
            title = "Upload Data", status = "warning", solidHeader = TRUE, width = 4,
            fileInput("file_upload", "Choose CSV/Excel File", 
                     accept = c(".csv", ".xlsx", ".xls")),
            p("System will automatically clean and validate headers."),
            hr(),
            verbatimTextOutput("file_validation")
          ),
          
          box(
            title = "Data Preview", status = "info", solidHeader = TRUE, width = 8,
            tableOutput("data_preview")
          )
        ),
        
        fluidRow(
          box(
            title = "Analysis Results", status = "success", solidHeader = TRUE, width = 12,
            plotOutput("data_plot", height = "400px")
          )
        )
      ),
      
      # --- SETTINGS TAB ---
      tabItem(tabName = "settings",
        fluidRow(
          box(
            title = "System Configuration", status = "warning", solidHeader = TRUE, width = 6,
            h4("Database Settings"),
            textInput("db_host", "Database Host", value = "localhost"),
            textInput("db_name", "Database Name", value = "research_db"),
            textInput("db_user", "Database User", value = "research_user"),
            passwordInput("db_password", "Database Password"),
            actionButton("test_db_btn", "Test Connection", class = "btn-info"),
            hr(),
            verbatimTextOutput("db_test_result")
          ),
          
          box(
            title = "API Keys", status = "warning", solidHeader = TRUE, width = 6,
            h4("External Services"),
            passwordInput("news_api_key", "News API Key"),
            passwordInput("scholar_api_key", "Semantic Scholar API Key"),
            actionButton("save_keys_btn", "Save Securely", class = "btn-success")
          )
        )
      ),
      
      # --- SYSTEM STATUS TAB ---
      tabItem(tabName = "status",
        fluidRow(
          box(
            title = "System Health", status = "success", solidHeader = TRUE, width = 12,
            h4("Connection Status"),
            verbatimTextOutput("system_status"),
            hr(),
            h4("Recent Logs"),
            verbatimTextOutput("recent_logs")
          )
        )
      )
    )
  )
)