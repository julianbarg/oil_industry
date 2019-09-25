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

load("data/maps.RData")
raw_df <- read_feather("data/dataset_2019-09-21.feather")
company_groups <- read_feather("data/company_groups.feather")

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("Pipeline Incidents in the US (2010-2018)"),

    sidebarLayout(
        sidebarPanel(
            verticalLayout(
                tabsetPanel(
                    tabPanel("Selections", 
                             checkboxInput("in_sample", 
                                           "Only select observations in sample?", 
                                           value=TRUE),
                             
                             # Selection group - Severity, offshore, commodity
                             splitLayout(
                                 radioButtons(inputId="severity",
                                              label="Severity:",
                                              choices=c("All", "Significant", "Serious"),
                                              selected="Significant"), 
                                 radioButtons(inputId="offshore", 
                                              label="On/Offshore:",
                                              choices=c("All", "Onshore only", "Offshore only"), 
                                              selected="Onshore only")
                                 ),
                             checkboxGroupInput(inputId="commodities", 
                                                label="Choose commodities:", 
                                                choices=unique(raw_df$Commodity),
                                                selected=names(sort(table(raw_df$Commodity), decreasing=TRUE)[1:3])),
                             
                             # Year selection logic
                             tags$br(),
                             tags$br(),
                             tags$br(),
                             conditionalPanel(
                                 condition = "input.single_year_select == false",
                                 sliderInput(inputId="years", 
                                             label="Years:", 
                                             min=2010, 
                                             max=2018,
                                             value=c(2010, 2018), 
                                             step=1,
                                             sep="",
                                             ticks=FALSE)
                             ),
                             conditionalPanel(
                                 condition = "input.single_year_select == true",
                                 sliderInput(inputId="year", 
                                             label="Year:", 
                                             min=2010, 
                                             max=2018,
                                             value=2010, 
                                             step=1,
                                             sep="",
                                             ticks=FALSE)
                             ),
                             checkboxInput("single_year_select", "Select single year", )
                        ), 
                    
                    tabPanel("Graphical elements",
                             sliderInput("jitter",
                                         "Jitter (zero means no jitter):",
                                         min = 0,
                                         max = 0.50,
                                         step = 0.01,
                                         ticks = FALSE,
                                         value = 0.00),
                             sliderInput("size",
                                         "Size of data points:",
                                         min = 0.5,
                                         max = 8,
                                         step = 0.5,
                                         ticks = FALSE,
                                         value = 2),
                             sliderInput("transparency",
                                         "Transparency:",
                                         min = 0.1,
                                         max = 1,
                                         step = 0.1,
                                         ticks = FALSE,
                                         value = 0.6),
                             radioButtons(inputId="shape",
                                          label="Select shape:",
                                          choices=c("X", "o", "O"),
                                          selected="X"), 
                             checkboxInput("density_onoff",
                                           "Show density",
                                           FALSE),
                             checkboxInput(inputId="rugplot",
                                           label="Display rug plot"),
                             selectizeInput(inputId="color",
                                            label="Color:",
                                            choices=colors(),
                                            selected="black",
                                            multiple=FALSE)
                        ),
                    
                    tabPanel("Map type", 
                             radioButtons(inputId="map_type",
                                          label="Choose map type:",
                                          choices = names(maps), 
                                          selected="terrain_large")
                        ),
                    
                    tabPanel("Organizations",
                             checkboxInput("group_on_off", "Groups"),
                             conditionalPanel(
                                 condition = "input.group_on_off == false",
                                 selectizeInput(inputId="organizations",
                                                             label="Choose organization(s):",
                                                             choices=unique(raw_df$Name),
                                                             selected=NULL,
                                                             multiple=TRUE)
                        ),
                             conditionalPanel(
                                 condition = "input.group_on_off == true",
                                 selectizeInput(inputId="group",
                                                label="Choose group(s):",
                                                choices=unique(company_groups$name),
                                                selected=NULL,
                                                multiple=TRUE)
                        )
                    ),
                    tabPanel("Causes",
                             checkboxGroupInput("causes",
                                                "Selected cause(s)", 
                                                choices=unique(raw_df$Cause), 
                                                selected=unique(raw_df$Cause))
                    ),
                    tabPanel("Various", 
                             checkboxInput("fire", "Caused fire"),
                             checkboxInput("explosion", "Caused explosion"),
                             checkboxInput("evacuation", "Triggered evacuation"),
                             checkboxInput("injury", "Caused injury"),
                             checkboxInput("year_shape", "Different shapes for years?"),
                             
                             tags$br(),
                             h4("Build your own filter"),
                             checkboxInput("filter1", "Activate first filter"),
                             conditionalPanel(
                                 condition = "input.filter1 == true",
                                 varSelectInput("variable1", "Select first variable:", raw_df, selectize=TRUE),
                                 splitLayout(
                                     selectizeInput('sign1', "Sign", c(">", "==", "<")),
                                     textInput("selection1", "Value")
                                 )
                             ),
                             checkboxInput("filter2", "Activate second filter"),
                             conditionalPanel(
                                 condition = "input.filter2 == true",
                                 selectizeInput("variable2", "Select second variable:", colnames(raw_df), selected=NULL),
                                 splitLayout(
                                     selectizeInput('sign2', "Sign", c(">", "==", "<")),
                                     textInput("selection2", "Value")
                                 )
                            )
                    )
                ),
                absolutePanel(tags$br(),
                              h3("Dataset information"), 
                              htmlOutput("selected_var")
                )
            )
        ),
        mainPanel(
            plotOutput("incidentMap")
        )
    )
))
