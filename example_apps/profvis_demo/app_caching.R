library(shiny)
library(ggplot2)

source("plot_cache.R")

ui <- fluidPage(
  titlePanel("Motor Trend Car Road Tests"),
  sidebarLayout(
    sidebarPanel(
      selectInput("xCol", "X axis", 
                  choices = colnames(mtcars), 
                  selected = colnames(mtcars)[1])
    ),
    mainPanel(imageOutput("plot"))
  )
)

plot_width <- 800
plot_height <- 400
plot_retina <- 2
plot_cache <- plotCache("mtcars_plot", NULL,
                        width = plot_width * plot_retina,
                        height = plot_height * plot_retina,
                        res = 72 * plot_retina,
                        function(x_axis) {
                          p <- ggplot(mtcars, aes_string(x = x_axis, y = "hp")) +
                            geom_point() +
                            geom_smooth(method = "lm", formula = y ~ x)
                          print(p)
                        })

server <- function(input, output) {
  output$plot <- renderImage({
    path <- plot_cache(input$xCol)
    list(
      src = path,
      width = "100%",
      height = "auto"
    )
  }, deleteFile = FALSE)
}

shinyApp(ui = ui, server = server)

# Profile in RStudio:
# library(profvis)
# profvis(runApp())