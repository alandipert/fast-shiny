library(shiny)
library(ggplot2)

ui <- fluidPage(
  titlePanel("Motor Trend Car Road Tests"),
  sidebarLayout(
    sidebarPanel(
      selectInput("xCol", "X axis", 
                  choices = colnames(mtcars), 
                  selected = colnames(mtcars)[1])
    ),
    mainPanel(plotOutput("plot"))
  )
)

server <- function(input, output) {
  output$plot <- renderPlot({
    x_axis <- input$xCol
    ggplot(mtcars, aes_string(x = x_axis, y = "hp")) +
      geom_point() +
      geom_smooth(method = "lm", formula = y ~ x)
  })
}

shinyApp(ui = ui, server = server)

# Profile in RStudio:
# library(profvis)
# profvis({runApp()})