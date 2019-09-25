#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(feather)

dataset <- read_feather("data/dataset_2019-09-25.feather")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    
    pipelines <- reactive({
        xvar_name <- quo_name(input$xvar)
        yvar_name <- quo_name(input$yvar)
        
        pipelines <- dataset
        
        if (input$sample == TRUE){
            pipelines <- subset(pipelines, Sample == TRUE)
        }
        
        if (input$largest == TRUE){
            pipelines <- subset(pipelines, Largest == TRUE)
        }
        
        if (input$commodity_filter == TRUE){
            pipelines <- subset(pipelines, Commodity %in% c("Crude", "Propane, Butane, etc.", "Gasoline, Diesel, etc."))
        }
        
        if (input$commodity_wrap == TRUE){
            pipelines <- pipelines %>%
                group_by(Commodity)
        }
        
        if (input$groups == TRUE){
            pipelines <- pipelines %>%
                group_by(Group)
        }
        
        pipelines <- pipelines %>%
            group_by(!! xvar_name := get(input$xvar), add = TRUE) %>%
            summarize(!! yvar_name := sum(get(input$yvar)))
        
        pipelines
    })

    output$pipelineTable <- renderTable({
        pipelines()
    })
    
    output$pipelinePlot <- renderPlot({
        xvar_name <- quo_name(input$xvar)
        yvar_name <- quo_name(input$yvar)
        
        
        plot <- pipelines() %>%
            ggplot(aes(y=get(input$yvar), x=get(input$xvar)))
        
        if (input$groups == FALSE){
            plot <- plot + 
                geom_col()
        } else {
            plot <- plot +
                geom_point(aes(group=Group, color=Group), size=2) +
                geom_line(aes(group=Group, color=Group), size=1)
        }
        
        plot <- plot +
            labs(x=xvar_name, y=yvar_name) + 
            theme(text = element_text(size=20), 
                  axis.text.x = element_text(angle=90, hjust=1))
        
        if (input$commodity_wrap == TRUE){
            plot <- plot +
                facet_wrap(.~Commodity)
        }
        
        plot
    }, height = 900)

})
