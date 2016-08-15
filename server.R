library(shiny)
library(data.table)
library(dplyr)
library(lattice)
library(stringr)
library(RColorBrewer)
library(shinythemes)

# Load data
Dataset_Info <- read.csv("databases/microarray_data_infosheet.csv")
Dataset_Info$Unique_ID <- apply(Dataset_Info[, c("GEO_ID", "Tissue", "Asthma")], 1, paste, collapse="_")
for (i in Dataset_Info$Unique_ID){
    assign(i, fread(paste0("databases/microarray_results/", i,".csv"), sep=" "))}
output.table <- data.frame()
Dataset_Info[is.na(Dataset_Info$PMID),"PMID"] <- ""

# heatmap colors
cols <-colorRampPalette(c("white","navyblue"))

# Server
shinyServer(function(input,output) {
  
  #reactive values
  curr_gene=reactive({input$curr_gene})
  
  #######################
  ## GEO studies table ##
  #######################
  #select GEO studies matching desired conditions;
  #Jessica's initial app had an "and" condition here; I changed it to "or"
  UserDataset_Info <- reactive({
    Dataset_Info=subset(Dataset_Info,Dataset_Info$Tissue %in% input$Tissue | Dataset_Info$Asthma %in% input$Asthma) 
    Dataset_Info})
  
  #add links for GEO_ID and PMID
  GEO_data <- reactive({UserDataset_Info() %>%
      mutate(GEO_ID_link = paste0("http://www.ncbi.nlm.nih.gov/gquery/?term=", GEO_ID), 
             PMID_link = paste0("http://www.ncbi.nlm.nih.gov/pubmed/?term=", PMID))})
  
  output$GEO_table <- renderTable({
    Dataset <- paste0("<a href='",  GEO_data()$GEO_ID_link, "' target='_blank'>",GEO_data()$GEO_ID,"</a>")
    PMID <- paste0("<a href='",  GEO_data()$PMID_link, "' target='_blank'>",GEO_data()$PMID,"</a>")
    Description <- GEO_data()$Description
    
    data.frame(Dataset, PMID, Description)
    
  }, sanitize.text.function = function(x) x, include.rownames=FALSE)

  #select and modify data used for levelplots and accompanying table
  output.tableforplot <- eventReactive(input$updategraph,{
    
    #select data for the gene currently selected
    data_filter <- function(x){
      x %>%
        filter(SYMBOL==curr_gene()) %>%
        select(logFC, P.Value, adj.P.Val) %>%
        filter(P.Value==min(P.Value))}
    
    #get data for given gene for each study selected
    for (i in UserDataset_Info()$Unique_ID){
      curr.gene.data=get(i,environment())
      
      if(any(tbl_vars(curr.gene.data)=="qValuesBatch")) {
        curr.gene.data <- (curr.gene.data %>%
                             select(-P.Value,-adj.P.Val) %>%
                             rename(P.Value=pValuesBatch) %>%
                             rename(adj.P.Val=qValuesBatch))}
      
      #use data_filter function from above to filter curr.gene.data 
      curr.gene.data <- data_filter(curr.gene.data)
      if(nrow(curr.gene.data) > 0) {
        curr.gene.data <- cbind(Unique_ID=i, curr.gene.data)
        #append curr.gene.data to all the other data that needs to be included in the levelplots
        output.table <- rbind(output.table, curr.gene.data)}}
    
    #preparing the data for levelplots
    #calculate the Fold Change, order by Fold Change for levelplots
    output.table <- mutate(output.table, Fold_Change=2^(logFC), neglogofP=(-log10(P.Value)))
    output.table <- output.table[order(output.table$Fold_Change),]})
  
  ########################################
  ## Data table accompanying levelplots ##
  ########################################
  data <- reactive({select(output.tableforplot(), Unique_ID, P.Value,Fold_Change,neglogofP)
    output.tableforplot()[rev(rownames(output.tableforplot())),]})
  
  data2 <- reactive({data()%>%
      select(Unique_ID,Fold_Change,adj.P.Val,P.Value)%>%
      mutate(Fold_Change=round(Fold_Change,digits=2),adj.P.Val=format(adj.P.Val, scientific=TRUE, digits=3), P.Value =format(P.Value, scientific=TRUE, digits=3))%>%
      rename(`Study ID`=Unique_ID, `P Value`=P.Value, `Q Value`=adj.P.Val, `Log 2 Fold Change`=Fold_Change)})
  
  output$tableforgraph <- renderTable(data2())
  
  ################
  ## Levelplots ##
  ################
  output.tableforplot2 <- reactive({output.tableforplot() %>% rename(' '=Fold_Change, ' '=neglogofP)})
  heatmapMAT <- eventReactive(input$updategraph,{output.tableforplot2()})
  
  plot_data_FC <- reactive({t(heatmapMAT()[5])})
  plot_data_pval <- reactive({test2 <- t(heatmapMAT()[6])})
  outp_names <- reactive({heatmapMAT[1]})
  
  
  #set up min & max boundaries for levelplots
  minFC <- reactive({if(max(plot_data_FC())<=1.5 & min(plot_data_FC())>=-1.5){
    minFC=-1.5} else {minFC=min(plot_data_FC())}})
  
  maxFC <- reactive({if(max(plot_data_FC())<=1.5 & min(plot_data_FC())>=-1.5){
    maxFC=1.5} else {maxFC=max(plot_data_FC())}})
  
  minNLOP <- reactive({0})
  maxNLOP <- reactive({if(max(plot_data_pval())<=1.5 & min(plot_data_pval())>=-1.5){
    maxNLOP=1.5} else {maxNLOP=max(plot_data_pval())}})
  
  # levelplots output for fold change & log p-value
  graphgene=eventReactive(input$updategraph,{curr_gene()})
  
  fc_plot <- reactive({print(levelplot(plot_data_FC(),
                                       col.regions=cols,
                                       xlab =NULL,
                                       ylab="GEO ID",
                                       main = "Fold Change",
                                       aspect=2,
                                       scales=list(x=list(cex=1,rot=35,tck = c(0,0,0,0)),
                                                   y=list(tck = c(1,0,0,0))),
                                       at=seq(minFC(), maxFC(), length.out=100)))})
  
  output$fc_plot <- renderPlot(fc_plot())
  
  pval_plot <- reactive({ print(levelplot(plot_data_pval(),
                                          col.regions=cols,
                                          xlab =NULL,
                                          ylab="GEO ID",
                                          main = "-log(p-value)",
                                          aspect=2,
                                          scales=list(x=list(cex=1,rot=35,tck = c(0,0,0,0)), 
                                                      y=list(tck = c(1,0,0,0))),
                                          at=seq(minNLOP(), maxNLOP(),length.out=100)))})
  
  output$pval_plot <- renderPlot(pval_plot())
  
  ### download buttons for GEO data and levelplots
  output$fc_download <- downloadHandler(
    filename= function(){paste0("Fold_change_heatmap_", graphgene(), "_", Sys.Date(), ".png")},
    content=function(file){
      png(file)
      print(imageFC())
      dev.off()})
  
  output$pval_download <- downloadHandler(
    filename= function(){paste0("-log(pval)_heatmap_", graphgene(), "_", Sys.Date(), ".png")},
    content=function(file){
      png(file)
      print(imageNLOP())
      dev.off()})
  
  output$geo_download <- downloadHandler(filename = function() {paste0('GEO_summary_table_ ',graphgene(), Sys.Date(), '.csv')},
                                         content = function(file) {write.csv(data(), file)})
  
  output$table_download <- downloadHandler(filename = function() {paste0('Heatmap_summary_table_',graphgene(), Sys.Date(), '.csv')},
                                         content = function(file) {write.csv(data(), file)})
})