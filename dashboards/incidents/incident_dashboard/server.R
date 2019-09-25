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

raw_df <- read_feather("data/dataset_2019-09-25.feather")
company_groups <- read_feather("data/company_groups.feather")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    incidents <- reactive({
        filtered_df <- raw_df
        
        # In sample (paper)
        if (input$in_sample == TRUE){
            filtered_df <- subset(filtered_df, in_sample == TRUE)
        }
        
        # Commodity & cause
        filtered_df <- subset(filtered_df, Commodity %in% input$commodities)
        filtered_df <- subset(filtered_df, Cause %in% input$causes)
        
        # Severity
        if (input$severity == "Significant"){
            filtered_df <- subset(filtered_df, Significant == TRUE)
        } else if (input$severity == "Serious"){
            filtered_df <- subset(filtered_df, Serious == TRUE)
        }
        
        # Time
        if (input$single_year_select == TRUE){
            filtered_df <- subset(filtered_df, Year == input$year)
        } else {filtered_df <- subset(filtered_df, Year >= input$years[1] & Year <= input$years[2])
        }
        
        # On/Offshore
        if (input$offshore == "Onshore only"){
            filtered_df <- subset(filtered_df, Offshore == "ONSHORE")
        } else if (input$offshore == "Offshore only"){
            filtered_df <- subset(filtered_df, Offshore == "OFFSHORE")
        }
        
        #Select organizations
        if (length(input$organizations > 0)){
            filtered_df <- subset(filtered_df, Name %in% input$organizations)
        } else if (length(input$group) > 0){
            selected_organizations <- subset(company_groups, name %in% input$group)$members
            filtered_df <- subset(filtered_df, ID %in% selected_organizations)
        }
        
        # Various
        if (input$fire == TRUE){
            filtered_df <- subset(filtered_df, Fire == TRUE)
        }
        if (input$explosion == TRUE){
            filtered_df <- subset(filtered_df, Explosion == TRUE)
        }
        if (input$evacuation == TRUE){
            filtered_df <- subset(filtered_df, !is.na(Evacuated) & Evacuated > 0)
        }
        if (input$injury == TRUE){
            filtered_df <- subset(filtered_df, !is.na(Injuries) & Injuries > 0)
        }
        # Build your own filters
        if (input$filter1 == TRUE & input$selection1 != ""){
            if (input$sign1 == ">"){
                filtered_df <- filtered_df[!is.na(filtered_df[[input$variable1]]) & (filtered_df[[input$variable1]] >  as.numeric(input$selection1)), ] 
            } else if (input$sign1 == "=="){
                filtered_df <- filtered_df[!is.na(filtered_df[[input$variable1]]) & (filtered_df[[input$variable1]] == as.numeric(input$selection1)), ] 
            } else if (input$sign1 == "<"){
                filtered_df <- filtered_df[!is.na(filtered_df[[input$variable1]]) & (filtered_df[[input$variable1]] <  strtoi(input$selection1)), ] 
            }
        }
        if (input$filter2 == TRUE & input$selection2 != ""){
            if (input$sign2 == ">"){
                filtered_df <- filtered_df[!is.na(filtered_df[[input$variable2]]) & (filtered_df[[input$variable2]] >  as.numeric(input$selection2)), ] 
            } else if (input$sign2 == "=="){
                filtered_df <- filtered_df[!is.na(filtered_df[[input$variable2]]) & (filtered_df[[input$variable2]] == as.numeric(input$selection2)), ] 
            } else if (input$sign2 == "<"){
                filtered_df <- filtered_df[!is.na(filtered_df[[input$variable2]]) & (filtered_df[[input$variable2]] <  as.numeric(input$selection2)), ] 
            }
        }
        
        
        filtered_df
    })

    map_choice <- reactive({
        input$map_type
    })
    
    shape_choice <- reactive(if (input$year_shape == FALSE){
        switch(input$shape, "X" = 4, "o" = 16, "O" = 19)
    } else {incidents()$Year - 2009})

    output$incidentMap <- renderPlot({
        req(input$shape)
        map <- ggmap(maps[[input$map_type]], base_layer = ggplot(incidents(), aes(Long, Lat)))            + 
            labs(x=element_blank(), 
                 y=element_blank()) +
            theme(text = element_text(size=20))
        
        if (input$groupcolor == FALSE){
            map <- map + 
                geom_point(color=input$color,
                           shape = shape_choice(),
                           # color="brown4",
                           size = input$size, 
                           alpha = input$transparency,
                           position = position_jitter(width = input$jitter, height = input$jitter)) 
        } else {
            map <- map + 
                geom_point(aes(color=Group),
                           shape = shape_choice(),
                           # color="brown4",
                           size = input$size, 
                           alpha = input$transparency,
                           position = position_jitter(width = input$jitter, height = input$jitter)) 
        }

            


        if (input$rugplot == TRUE){
            map <- map +
                geom_rug(alpha = 0.1, position="jitter")
        }
        
        if (input$density_onoff) {
            map <- map +
                geom_density2d()
        }
        
        map
    }, width = 800, height = 800)
    
    output$selected_var <- renderText({ 
        paste0("Your dataset contains <b>", nrow(incidents()), "</b> observations.")
    })

})
