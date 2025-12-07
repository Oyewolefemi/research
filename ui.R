# ui.R
dashboardPage(
  skin = "black", # Professional, clean look
  
  dashboardHeader(title = "Research Hub"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Trend Watcher", tabName = "trends", icon = icon("eye")),
      menuItem("Data Lab", tabName = "datalab", icon = icon("flask")),
      menuItem("Settings", tabName = "settings", icon = icon("cogs"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # --- MODULE 1: Trend Watcher ---
      tabItem(tabName = "trends",
        fluidRow(
          # Simple Input Box
          box(
            title = "New Search Topic", status = "primary", solidHeader = TRUE, width = 4,
            textInput("topic_input", "What should we track?", placeholder = "e.g., Bamboo Fiber"),
            selectInput("source_input", "Source", choices = c("Scientific Papers", "Global News")),
            actionButton("add_topic_btn", "Start Tracking", class = "btn-success")
          ),
          # The "Magic" Feed
          box(
            title = "Live Intelligence Feed", status = "primary", width = 8,
            p("Recent updates found by the system:"),
            tableOutput("articles_table")
          )
        )
      ),
      
      # --- MODULE 2: Data Lab ---
      tabItem(tabName = "datalab",
        fluidRow(
          box(
            title = "Upload Data", status = "warning", solidHeader = TRUE, width = 4,
            fileInput("file_upload", "Choose CSV/Excel File", accept = ".csv"),
            p("System will automatically clean and validate headers.")
          ),
          box(
            title = "Analysis Results", width = 8,
            plotOutput("data_plot")
          )
        )
      ),
      
      # --- MODULE 3: Settings ---
      tabItem(tabName = "settings",
        box(
          title = "System Configuration", width = 12,
          passwordInput("api_key", "Update API Key"),
          actionButton("save_key", "Save Securely")
        )
      )
    )
  )
)