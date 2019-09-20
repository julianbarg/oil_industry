#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)

load("data/maps.RData")

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("Pipeline Incidents in the US (2010-2018)"),

    sidebarLayout(
        sidebarPanel(
            tabsetPanel(
                tabPanel("Selections", 
                         radioButtons(inputId="severity",
                                      label="Severity:",
                                      choices=c("All", "Significant", "Serious"),
                                      selected="Significant"), 
                         radioButtons(inputId="offshore", 
                                      label="On/Offshore:",
                                      choices=c("All", "Onshore only", "Offshore only"), 
                                      selected="Onshore only"),
                         sliderInput(inputId="years", 
                                     label="Years:", 
                                     min=2010, 
                                     max=2018,
                                     value=c(2010, 2018), 
                                     step=1,
                                     ticks=FALSE)
                    ), 
                tabPanel("Map type", 
                         radioButtons(inputId="map_type",
                                      label="Choose map type:",
                                      choices = names(maps), 
                                      selected="terrain_background"))
            )            

        ),
        mainPanel(
            plotOutput("incidentMap")
        )
    )
))
