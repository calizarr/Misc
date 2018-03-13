library(topGO)
library(GO.db)

mappings <- List(Sbicolor = "Sbicolor_v2.1_255.GO.tsv", Zmays = "Zmays_284_6a.GO.tsv", Sviridis = "Sviridis.311.GO.all.tab")
clusters <- List(Sbicolor = "/home/hpriest/TBrutnell/forSarit/Updated/SingleNets/Sorghum.net.primary/Clusters",
                 Zmays = "/home/hpriest/TBrutnell/forSarit/Updated/SingleNets/Maize.net.primary/Clusters",                 
                 Sviridis = "/home/hpriest/TBrutnell/forSarit/Updated/SingleNets/Setaria.net.primary/Clusters")

new.mappings <- List(Sbicolor = "")


GeneID2GO <- readMappings(file = mappings[[1]])
## GeneNames <- names(GeneID2GO)
## myList <- read.table(file = file.path(clusters[[1]], dir(clusters[[1]])[1]), row.names = 1)
## smallGeneNames <- row.names(myList)
## goList <- factor(as.integer(GeneNames %in% smallGeneNames))
## names(goList) <- GeneNames
## GOdata <- new("topGOdata", ontology = "BP", allGenes = goList, annot = annFUN.gene2GO, gene2GO = GeneID2GO)
## GOdata
## FishRes <- runTest(GOdata,algorithm="classic",statistic="fisher")
## Table <- GenTable(GOdata,classic=FishRes,ranksOf="classic")
## Table$GO.ID
## Table$classic
## adjustedP = p.adjust(Table$classic,method="fdr")
## adjustedP



xx <- as.factor(unlist(GeneID2GO))
df <- data.frame(Gene = names(xx), GO.ID = unname(xx))
goterms <- Term(GOTERM)
