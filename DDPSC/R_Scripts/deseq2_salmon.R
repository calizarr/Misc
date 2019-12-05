
## Because we need a header?
source("https://bioconductor.org/biocLite.R")
source("deseq2_salmon_helper.R")
library(tximport)
library(biomaRt)
library(readr)
library(DESeq2)
## All of this is plotting
library(pheatmap)
library(RColorBrewer)
library(PoiClaClu)
library(ggplot2)
library(factoextra)
## Parallelization
library(BiocParallel)
## Arabidopsis thaliana database can be used to expand tables
library("org.At.tair.db")
## Interactive plots and reports
library(regionReport)
library(ReportingTools)
## Tree drawing
library(treemap)
library(data.tree)
library(GenomicFeatures)

## Getting genome names
genomes <- dir("../kallisto_output")
## For now REMOVE LATER
genomes <- genomes[!(genomes %in% c("Setaria", "Sorghum"))]

## Make transcript databases transcript to gene
orig.path <- "/shares/tmockler_share/clizarraga/Sarit_Collab/Network_analysis/DESeq2/references"
gffs <- list(
    ## Maize = file.path(orig.path, "Zea_mays.AGPv3.21.gff3"),
    Maize = file.path(orig.path, "Zmays_284_5b+.gene_exons.gff3"),
    Setaria = file.path(orig.path, "Sviridis_311_v1.1.gene_exons.gff3"),
    Sorghum = file.path(orig.path, "Sbicolor_v2.1_255_gene.gff3")
)
organisms <- list(Maize = "Zea mays", Setaria = "Setaria viridis", Sorghum = "Sorghum bicolor")

txdbs <- lapply(genomes, function(gen) {
    makeTxDbFromGFF(file = gffs[[gen]], format = "auto", dataSource = "Phytozome", organism = organisms[[gen]],
                    circ_seqs = character())
})
names(txdbs) <- genomes

## Getting the files to use them to create the sample info table at least genome, cell type, and replicate
files <- lapply(genomes, function(gen) {
    sapply(dir(file.path("../kallisto_output", gen)), function(id) {
        file.path("../kallisto_output", gen, id, "abundance.tsv")
    })
})
names(files) <- genomes

## Creating sample info from filename
sample.info <- lapply(genomes, function(gen) {
    ## The sub regex checks at the start of the string up to NOT BM [^BM] and then captures everything afterward and removes them.
    ## The strsplit regex looks for the last and final dash. It's a look ahead to make sure there are no more dashes after that.
    x <- strsplit(sub("^[^BM]*", "", names(files[[gen]])), "-(?=[^-]+$)", perl = TRUE)
    ## Setaria is cute and requires an extra removal that doesn't affect the others.
    x <- lapply(x, function(id) { gsub("\\.cutadapt\\.3pQtrim", "", id) })
    ## Making it a data frame!
    x <- data.frame(do.call(rbind, x))
    names(x) <- c("cell", "rep")
    return(x)
})
names(sample.info) <- genomes

## Adding in and moving stuff around
sample.info <- lapply(genomes, function(gen) {
    sections <- gsub("M[_-]?", "", gsub("BS?[-_]?", "", toupper(as.character(sample.info[[gen]]$cell))))
    cell.type <- gsub("[_T-\\d].*", "", toupper(as.character(sample.info[[gen]]$cell)), perl = TRUE)
    sample.info[[gen]] <- cbind(sample.info[[gen]], sections)
    sample.info[[gen]] <- cbind(sample.info[[gen]], cell.type)
    ## Dictionary style map replacement which is awesome using the names attribute as a dict
    map <- setNames(levels(sample.info[[gen]]$sections), c("T0", "T1", "T2"))
    sample.info[[gen]]$timepoint <- as.factor(names(map[sample.info[[gen]]$sections]))
    return(sample.info[[gen]])
})
names(sample.info) <- genomes

results.dir <- "DESeq2_Results"
dir.create(results.dir)

s2c <- sample.info
## Drawing a tree of the experiment
experiments <- lapply(genomes, function(gen) {
    s2c[[gen]]$pathString <- paste(gen, s2c[[gen]]$cell.type, s2c[[gen]]$timepoint, s2c[[gen]]$replicate, sep="/")
    experiment <- as.Node(s2c[[gen]])
    return(experiment)
})


## Making transcript to gene data frames and databases
t2gs <- lapply(genomes, function(gen) {
    txdb <- txdbs[[gen]]
    k <- keys(txdb, keytype = "GENEID")
    t2g <- select(txdb, keys = k, keytype = "GENEID", columns = "TXNAME")
    t2g <- t2g[, 2:1]
    t2g <- dplyr::rename(t2g, target_id = TXNAME, ens_gene = GENEID)
    t2g <- t2g[order(t2g$ens_gene), ]
    return(t2g)
})
names(t2gs) <- genomes

## t2g.table <- read.table(files[["Maize"]][[1]], sep="\t", header=T)
## t2g <- data.frame(target_id = as.character(t2g.table[, "target_id"]))
## t2g[, "gene_id"] <- gsub("_T\\d+", "", t2g[, "target_id"])
## t2gs[["Maize"]] <- t2g

## lapply(c("t2g", "t2g.table", "t2g"), function(x) { rm(x) })

## Import transcript-level estimates
txis <- lapply(genomes, function(gen) {
    tximport(files[[gen]], type = "kallisto", tx2gene = t2gs[[gen]], reader = read_tsv)
})
names(txis) <- genomes

## sampleTable creation
sampleTables <- lapply(genomes, function(gen) {
    sampleTable <- s2c[[gen]]
    sampleTable[] <- lapply(sampleTable, factor)
    rownames(sampleTable) <- colnames(txis[[gen]]$counts)
    return(sampleTable)
})
names(sampleTables) <- genomes

#################### DIFFERENTIAL EXPRESSION ANALYSIS ################################
threads <- 4
register(MulticoreParam(workers = threads))


## Making subsets on genomes and on sections
results <- lapply(genomes, function(gen) {
    print(paste0("Running through this genome: ", gen))
    dds <- DESeqDataSetFromTximport(txi = txis[[gen]], colData = sampleTables[[gen]],
                                    design = ~ cell.type)
    subsets <- lapply(levels(dds$sections), function(sect) {
        print(paste0("Running through with this"," Genome: ",gen, " Section: ", sect))
        dds.sub <- dds[, dds$sections %in% c(sect)]
        colData(dds.sub) <- droplevels(colData(dds.sub))
        dds.sub <- DESeq(dds.sub, test = "LRT", reduced = ~ 1, parallel = TRUE)
        ## dds.sub <- DESeq(dds.sub, test = "Wald", parallel = TRUE)
        res <- results(dds.sub, alpha = 0.05, parallel = TRUE)
        return(list(dds = dds.sub, res = res))
    })
    names(subsets) <- paste0("Section_", levels(dds$sections))
    return(subsets)
})
names(results) <- genomes

write.out <- lapply(genomes, function(gen) {
    results <- results[[gen]]
    lapply(seq_along(results), function(idx) {
        sect <- names(results)[[idx]]
        print(paste0("Section is : ", sect))
        res <- results[[idx]][[2]]
        res.Ordered <- res[order(res$padj), ]
        res.OrderedDF <- as.data.frame(res.Ordered)
        res.OrderedDF$genes <- rownames(res.OrderedDF)
        res.OrderedDF <- res.OrderedDF[, c("genes", setdiff(names(res.OrderedDF), "genes"))]
        res.OrderedDF[, "significant"] <- ifelse(res.OrderedDF$padj < 0.05, "YES", "NO")
        write.csv(res.OrderedDF, file.path(results.dir, paste0(gen, "_", sect,"_comparisons_results.csv")), row.names = FALSE)
        sink(file.path(results.dir, paste0("Summary_", gen,"_",sect,"_M_v_BS.txt")))
        print(summary(res))
        sink()
        return(NULL)
    })
})

## Extracting abundances for Todd
indices <- unique(paste0(sampleTable$treatment,"-.*-",sampleTable$timepoint))
txi.agg.abundance <- do.call(cbind, lapply(indices, function(i) { rowMeans(txi$abundance[, grep(i, colnames(txi$abundance), val = T)]) }))
colnames(txi.agg.abundance) <- gsub("-.*", "", indices, fixed = TRUE)
## txi.agg.abundance <- do.call(cbind, lapply(ind, function(i) rowMeans(txi.reorder$abundance[, i])))
## txi.agg.length <- do.call(cbind, lapply(ind, function(i) rowMeans(txi.reorder$length[, i])))
## txi.agg.counts <- do.call(cbind, lapply(ind, function(i) rowMeans(txi.reorder$counts[, i])))
## txi.agg <- list(abundance = txi.agg.abundance, counts = txi.agg.counts, length = txi.agg.length)

## txi.agg.name <- lapply(txi.agg, function(x) { colnames(x) <- new.names;return(x) })
write.csv(txi.agg.abundance, file.path(results.dir, "Per_gene_abundance_counts_length.csv"))
