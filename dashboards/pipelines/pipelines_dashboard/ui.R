#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(feather)

dataset <- read_feather("data/dataset_2019-09-25.feather")

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("US Pipeline miles"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            tabsetPanel(
                tabPanel(
                    "Variables", 
                     tags$br(),
                     checkboxInput("sample", "In sample"),
                     selectizeInput("xvar", 
                                    "X-axis", 
                                    choices=colnames(dataset), 
                                    selected="Year"),
                     selectizeInput("yvar", 
                                    "Y-axis", 
                                    choices=colnames(dataset), 
                                    selected="HCA Miles"),
                     checkboxInput("commodity_filter",
                                   "Filter only commodities in sample", 
                                   TRUE),
                     checkboxInput("commodity_wrap", 
                                   "Facet by commodity"), 
                     checkboxInput("groups", 
                                   "Show company groups vs. non groups"),
                     checkboxInput("largest",
                                   "Show only largest five organizations")
                    )
                #     ),
                # tabPanel(
                #     "Presets",
                #     tags$br(),
                #     checkboxGroupInput(
                #         "preset", 
                #         "Select preset",
                #         choices = c("Test" = "test")
                #     )
                # )
            )
        ),

        # Show a plot of the generated distribution
        mainPanel(
            plotOutput("pipelinePlot")
            # plotOutput("pipelinePlot"),
            # tableOutput("pipelineTable")
        )
    )
))
