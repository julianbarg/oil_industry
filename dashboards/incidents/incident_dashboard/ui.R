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

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("Pipeline Incidents in the US (2010-2018)"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            tabsetPanel(
                tabPanel("Selections", 
                         radioButtons(inputId="severity",
                                      label="Severity:",
                                      choices=c("All", "Significant", "Serious"),
                                      selected="Significant"), 
                         sliderInput(inputId="years", 
                                     label="Years:", 
                                     min=2010, 
                                     max=2018,
                                     value=c(2010, 2018), 
                                     step=1,
                                     ticks=FALSE)
                    )
            )            

        ),
        mainPanel(
            plotOutput("incidentMap")
        )
    )
))
