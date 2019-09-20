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
library(ggmap)
library(feather)

# Load data
load("data/maps.RData")

raw_df <- read_feather("data/dataset_2019-09-20.feather")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    incidents <- reactive({
        req(input$severity)
        req(input$years)
        req(input$offshore)
        filtered_df <- raw_df
        
        # Severity
        if (input$severity == "Significant"){
            filtered_df <- subset(filtered_df, Significant == TRUE)
        } else if (input$severity == "Serious"){
            filtered_df <- subset(filtered_df, Serious == TRUE)
        }
        
        # Time
        filtered_df <- subset(filtered_df, Year >= input$years[1] & Year <= input$years[2])
        
        # On/Offshore
        if (input$offshore == "Onshore only"){
            filtered_df <- subset(filtered_df, Offshore == "ONSHORE")
        } else if (input$offshore == "Offshore only"){
            filtered_df <- subset(filtered_df, Offshore == "OFFSHORE")
        }
        
        filtered_df
    })

    map_choice <- reactive({
        input$map_type
    })

    output$incidentMap <- renderPlot({
        map <- ggmap(maps[[input$map_type]], base_layer = ggplot(incidents(), aes(Long, Lat))) +
            geom_point()

        map
            

        # # generate bins based on input$bins from ui.R
        # x    <- faithful[, 2]
        # bins <- seq(min(x), max(x), length.out = input$bins + 1)
        # 
        # # draw the histogram with the specified number of bins
        # hist(x, breaks = bins, col = 'darkgray', border = 'white')
    }, width = 800, height = 800)

})
