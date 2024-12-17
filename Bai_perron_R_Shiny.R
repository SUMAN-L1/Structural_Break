library(shiny)
library(readxl)
library(tseries)
library(strucchange)

# UI
ui <- fluidPage(
  titlePanel("Structural Break: Bi-perron test by SumanEcon"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload Excel File (xlsx format)", 
                accept = c(".xlsx")),
      textInput("year_col", "Column Name for Years:", value = "Year"),
      textInput("data_col", "Column Name for Data:", value = "Total_Exports"),
      actionButton("analyze", "Perform Analysis")
    ),
    
    mainPanel(
      plotOutput("timeSeriesPlot"),
      verbatimTextOutput("breakSummary"),
      plotOutput("breakpointsPlot"),
      plotOutput("stabilityPlot")
    )
  )
)

# Server
server <- function(input, output, session) {
  data <- reactive({
    req(input$file)
    read_excel(input$file$datapath)
  })
  
  analysisResults <- reactive({
    req(input$file, input$year_col, input$data_col)
    
    # Load the data
    ds <- data()
    
    # Ensure the columns are properly selected
    req(input$year_col %in% names(ds), input$data_col %in% names(ds))
    
    # Convert data to time series
    years <- ds[[input$year_col]]
    data_col <- ds[[input$data_col]]
    
    # Create time series
    start_year <- min(years)
    end_year <- max(years)
    TE <- ts(data_col, start = start_year, end = end_year, frequency = 1)
    
    # Perform Breakpoints Analysis
    BP_test <- breakpoints(TE ~ 1, h = 4)
    
    # Stability Diagnostics
    Addition_BP <- efp(TE ~ breakfactor(BP_test), type = "OLS-CUSUM")
    
    list(TE = TE, BP_test = BP_test, Addition_BP = Addition_BP)
  })
  
  output$timeSeriesPlot <- renderPlot({
    req(analysisResults())
    
    res <- analysisResults()
    TE <- res$TE
    BP_test <- res$BP_test
    
    # Plot original data
    plot(TE, main = "Time Series with Breakpoints", 
         xlab = "Year", ylab = "Data", col = "blue", lwd = 2)
    
    # Add breakpoints
    break_years <- start(TE)[1] + BP_test$breakpoints - 1
    abline(v = break_years, col = "red", lty = 2, lwd = 2)
    
    # Add legend
    legend("topright", legend = c("Original Data", "Breakpoints"),
           col = c("blue", "red"), lty = c(1, 2), lwd = c(2, 2))
  })
  
  output$breakSummary <- renderPrint({
    req(analysisResults())
    summary(analysisResults()$BP_test)
  })
  
  output$breakpointsPlot <- renderPlot({
    req(analysisResults())
    
    BP_test <- analysisResults()$BP_test
    
    # Plot BIC and RSS against breakpoints
    plot(BP_test, main = "Structural Break Points")
  })
  
  output$stabilityPlot <- renderPlot({
    req(analysisResults())
    
    Addition_BP <- analysisResults()$Addition_BP
    
    # Plot Stability Diagnostics
    plot(Addition_BP, main = "Model Stability Diagnostics (OLS-CUSUM)")
  })
}

# Run the app
shinyApp(ui, server)
