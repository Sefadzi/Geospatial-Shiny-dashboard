function(input, output){
  
  data <- reactive(({
    req(input$data)
    read.csv(input$data$datapath)
  }))
  
  map <- reactive({
    req(input$data)
    
    shpdf <- input$map
    
    tempdirname <- dirname(shpdf$datapath[1])
    
    # rename files
    for (i in 1:nrow(shpdf)) {
      file.rename(
        shpdf$datapath[i], paste0(tempdirname, "/",shpdf$name[i])
      )
    }
    map <- readOGR(paste(tempdirname,shpdf$name[grep(pattern = "*.shp$", shpdf$name)],sep =  "/"))
    return(map)
  })
  
  
  
  output$data1 = renderDT(
    datatable(data())
  )
  
  output$plot = renderDygraph({
    data <- data()
    dataxts <- NULL
    counties <- unique(data$county)
    
    for (i in 1:length(counties)) {
      datacounty <- data[data$county == counties[i],]
      dd <- xts(
        datacounty[,input$variable],
        as.Date(paste0(datacounty$year, "-01-01"))
      )
      dataxts <- cbind(dataxts, dd)
    }
    colnames(dataxts) <- counties
    
    dygraph(dataxts) %>%
      dyHighlight(highlightSeriesBackgroundAlpha = 0.2) -> d1
    
    d1$x$css <- "
    .dygraph-legend > span {display:none;}
    .dygraph-legend > span.highlight { display: inline; }
    "
    d1
  })
  
  output$map <- renderLeaflet({
    if(is.null(data()) | is.null(map())){
      return(NULL)
    }
    map = map()
    df = data()
    datafiltered <- df[which(df$year == input$year),]
    ordercounties <- match(map@data$NAME, datafiltered$county)
    map@data <- datafiltered[ordercounties, ]
    
    map$plotvariable <- as.numeric(
      map@data[, input$variable]
    )
    
    # Create leaflet
    # CHANGE map$cases by map$variableplot
    pal <- colorBin("YlOrRd", domain = map$plotvariable, bins = 7)
    
    # CHANGE map$cases by map$variableplot
    labels <- sprintf("%s: %g", map$county, map$plotvariable) %>%
      lapply(htmltools::HTML)
    
    # Change cases by variable plot
    l = leaflet(map,height=2000, width=2000) %>%
      addTiles() %>%
      addPolygons(
        fillColor = ~ pal(plotvariable),
        color = "white",
        dashArray = "3",
        fillOpacity = 0.7,
        label = labels
      )%>%
      # CHANGE cases by variableplot
      leaflet::addLegend(
        pal = pal, values = ~plotvariable,
        opacity = 0.7, title = NULL
      )
  })
}