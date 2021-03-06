library(shinythemes)

# Define UI for application that displays GEO results based on user choices
ui <- shinyUI(fluidPage(theme = shinytheme("cosmo"), 
                        #h1(strong("REALGAR"), align="center", style = "color: #9E443A;"),
                        h3(strong("Reducing Associations by Linking Genes And transcriptomic Results"), align="center", style = "color: #9E443A;"), hr(),
                        p("REALGAR is an integrated resource of tissue-specific results from expression studies. ",
                          "This app brings together microarray expression data from the ", 
                          a("Gene Expression Omnibus (GEO),", href="http://www.ncbi.nlm.nih.gov/geo/"),
                          " transcript data from ",
                          a("GENCODE,", href="http://www.gencodegenes.org/"), 
                          " genome-wide association study (GWAS) data from ",
                          a("GRASP", href="https://grasp.nhlbi.nih.gov/Search.aspx"), 
                          " and glucocorticoid receptor binding sites from ",
                          a("UCSC's ENCODE", href="https://genome.ucsc.edu/ENCODE/"),
                          " allowing researchers to access a breadth of information with a click. ",  
                          "We hope REALGAR's disease-specific and tissue specific information ",
                          "will facilitate prioritization and experiment design, leading to clinically actionable insights."), br(),
                        
                        wellPanel(fluidRow(align = "left",
                                           column(5,  
                                                  
                                                  fluidRow(column(5, h4("Select options:"),align = "left")), 
                                                  fluidRow(column(5,checkboxGroupInput(inputId="Tissue", label="Tissue", choices=c("Bronchial epithelium"="BE","Lens epithelial cell" = "LEC",
                                                                                                                              "Nasal epithelium"="NE","CD4"="CD4","CD8"="CD8","PBMC"="PBMC","White blood cell"="WBC", "Airway smooth muscle"="ASM",
                                                                                                                              "BAL"="BAL", "Whole lung"="Lung","Lymphoblastic leukemia cell" = "chALL","MCF10A-Myc" = "MCF10A-Myc",
                                                                                                                              "Macrophage" = "MACRO","Osteosarcoma U2OS cell" = "U2O", "Lymphoblastoid cell" = "LCL"),selected="BE"),
                                                                  actionButton("selectall","Select/unselect all tissues", style="color: #fff; background-color: #337ab7; border-color: #2e6da4")),
                                                      column(5,
                                                             fluidRow(checkboxGroupInput(inputId="Asthma", label="Asthma Type", choices=c("Allergic asthma"="allergic_asthma",
                                                                                                                                          "Severe asthma"="severe_asthma","Asthma"="asthma","Mild asthma"="mild_asthma","Non-allergic asthma"=
                                                                                                                                              "non_allergic_asthma", "Asthma and rhinitis"="asthma_and_rhinitis"), selected="asthma")),
                                                             fluidRow(radioButtons(inputId="GC_included", label="Treatment", 
                                                                                   choice = c("Glucocorticoid treatment" = "GC", "No treatment" = ""), select = "")),
                                                             fluidRow(textInput(inputId="curr_gene",label="Type the official gene symbol:", value= "GAPDH"),
                                                                      tags$head(tags$style(type="text/css", "#curr_gene {width: 190px}"))),
                                                             fluidRow(img(src="http://shiny.rstudio.com/tutorial/lesson2/www/bigorb.png", height=35, width=38),
                                                                      "Created with RStudio's ",
                                                                      a("Shiny", href="http://www.rstudio.com/shiny"))))),
                                           column(7,align="left",
                                                  fluidRow(h4("Datasets loaded:")),
                                                  fluidRow(p("Click on links to access the datasets and studies referenced in the table.")),
                                                  fluidRow(DT::dataTableOutput(outputId="GEO_table"))))),
                        
                        
                        mainPanel(hr(),
                                  fluidRow(br(),
                                           column(4,plotOutput(outputId="forestplot_asthma",width="340px", height="650px"),align="left"),
                                           column(3,plotOutput(outputId="forestplot_GC",width="300px", height="650px"),align="left"),
                                           column(5,plotOutput(outputId="pval_plot_outp",width="420px", height="650px"),align="right"),
                                           column(4, downloadButton(outputId="asthma_fc_download",label="Download asthma forest plot"), align="center"),
                                           column(4, downloadButton(outputId="GC_fc_download",label="Download GC forest plot"), align="center"),
                                           column(4, downloadButton(outputId="pval_download", label="Download p-value plot"), align="center")),
                                  
                                  fluidRow(br(),
                                      column(12, h5(strong("Results Used to Create Plots Above")), align = "center")),
                                  
                                  fluidRow(
                                           column(10, offset= 1, DT::dataTableOutput(outputId="tableforgraph"), align="center"),
                                           column(12, downloadButton(outputId="table_download", label="Download table"), align="center")),br(), hr(), width = 12,
                                  
                                  fluidRow(column(12, p("Transcripts for the selected gene are displayed here. ",
                                                        "Any SNPs and/or GR binding sites that fall within the gene ",
                                                        "or within +/- 10kb of the gene are also displayed, ",
                                                        "each in a separate track. GR binding sites are colored by the ",
                                                        "ENCODE binding score, ",
                                                        "with the highest binding scores corresponding to the darkest color. ",
                                                        "SNPs are colored by p-value, with the lowest p-values corresponding to the darkest color.",
                                                        "All SNP p-values are <=0.05 and are obtained directly",
                                                        "from the study in which the association was published.")),
                                           column(12, downloadButton(outputId="gene_tracks_download", label="Download gene tracks"), align="center"), br(),
                                           column(12, align="center", plotOutput(outputId="gene_tracks_outp2"), br(), br())))))
