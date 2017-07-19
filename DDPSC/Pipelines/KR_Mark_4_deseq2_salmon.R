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

results.dir <- "DESeq2_Results"
dir.create(results.dir)
## Get the csv for the entire sequence experiments.
sample.info <- read.csv("Mark_IV_POC3b_read_filename_identifiers.csv", na.strings = "")
## Removing the experiment that isn't this one
sample.info <- sample.info[sample.info$Exp == "POC3b", ]
sample.info <- droplevels(sample.info)
## Removing plate wells that weren't sequenced.
sample.info <- sample.info[!(is.na(sample.info$Plate.Well)), ]

## Loading SampleSheet from MOGene
sample.sheet <- read.csv("SampleSheet.csv", na.strings = "")
## Keeping only non only NA columns
sample.sheet <- sample.sheet[, !(colSums(is.na(sample.sheet)) > 0)]
## Merge on the Well names
sample.info <- merge(sample.info, sample.sheet, by.y = "Sample_Well", by.x = "Plate.Well")
sample.info$label <- sample.info$Plate.Well
sample.info$Replicate <- gsub("rep", "", sample.info$Replicate)

s2c <- data.frame(
    label = sample.info$label,
    treatment = sample.info$Treatment,
    timepoint = sample.info$Timepoint,
    replicate = sample.info$Replicate
    )

## Drawing a tree of the experiment
s2c$pathString <- paste("Arabidopsis_thaliana", s2c$treatment, s2c$timepoint, s2c$replicate, sep="/")
experiment <- as.Node(s2c)
## plot(experiment)

files <- sapply(dir("results"), function(id) file.path("results", id, "salmon", "quant.sf"))
files <- files[-grep("Undetermined", files)]
names(files) <- paste0(s2c$treatment,"-",s2c$replicate,"-",s2c$timepoint)

## Adding Arabidopsis Thaliana genes from biomaRt
txdb <- org.At.tair.db
mart <- biomaRt::useMart(biomart = "plants_mart",
                         dataset = "athaliana_eg_gene",
                         host = 'plants.ensembl.org')

t2g <- biomaRt::getBM(attributes = c("ensembl_transcript_id", "ensembl_gene_id",
                          "external_gene_name"), mart = mart)
## t2g <- biomaRt::getBM(attributes = c("ensembl_transcript_id", "ensembl_gene_id",
##                           "external_gene_id", "go_accession"), mart = mart)

t2g <- dplyr::rename(t2g, target_id = ensembl_transcript_id,
                     ens_gene = ensembl_gene_id, ext_gene = external_gene_name)

t2g <- t2g[order(t2g$ens_gene), ]

gene.symbols <- t2g[!duplicated(t2g$ens_gene), ]

## Import transcript-level estimates
txi <- tximport(files, type = "salmon", tx2gene = t2g, reader = read_tsv)

sampleTable <- s2c
sampleTable[] <- lapply(sampleTable, factor)
sampleTable$treatment <- relevel(sampleTable$treatment, "Untreated")
sampleTable$pathString <- NULL
sampleTable$number <- NULL
rownames(sampleTable) <- colnames(txi$counts)

(dds <- DESeqDataSetFromTximport(txi = txi, colData = sampleTable, design = ~ treatment))

#################### BEGIN DIFFERENTIAL EXPRESSION ANALYSIS ####################
(dds <- DESeqDataSetFromTximport(txi = txi, colData = sampleTable, design = ~ treatment))

## We begin visualizing the entire pipeline with RLD to see it, but we differentially express on raw samples.
dds <- dds[ rowSums(counts(dds)) > 1, ]

rld <- rlog(dds, blind=FALSE)

dds <- estimateSizeFactors(dds)

## Scatterplot of transformed counts from two samples. Shown are scatterplots using the log2
## transform of normalized counts (left side) and using the rlog (right side).
## We can see how genes with low counts (bottom left-hand corner) seem to be excessively variable
## on the ordinary logarithmic scale, while the rlog transform compresses differences
## for the low count genes for which the data provide little information about differential expression.
png(filename = "rlog_comparison_two_samples.png", width = 480*2, height = 480*2, res = 100)
par( mfrow = c( 1, 2 ) )
plot(log2(counts(dds, normalized=TRUE)[,c(1,10)] + 1),
     pch=16, cex=0.3)
plot(assay(rld)[,c(1,10)],
     pch=16, cex=0.3)
dev.off()

## Measuring similarity between samples
sampleDists <- dist(t(assay(rld)))

## Normal distance heatmap
sampleDistMatrix <- as.matrix(sampleDists)
rownames(sampleDistMatrix) <- paste0(rld$treatment,"-",rld$replicate)
colnames(sampleDistMatrix) <- NULL
colors <- colorRampPalette(rev(brewer.pal(9, "Blues")) )(255)

png(filename = "Standard_heatmap.png", width = 480*2, height = 480*2, res = 100)
pheatmap(sampleDistMatrix,
         clustering_distance_rows=sampleDists,
         clustering_distance_cols=sampleDists,
         col=colors)
dev.off()

## Poisson Distance heatmap
poisd <- PoissonDistance(t(counts(dds)))

samplePoisDistMatrix <- as.matrix( poisd$dd )
rownames(samplePoisDistMatrix) <- paste0(rld$treatment,"-",rld$replicate)
colnames(samplePoisDistMatrix) <- NULL

png(filename = "Poisson_heatmap.png", width = 480*2, height = 480*2, res = 100)
pheatmap(samplePoisDistMatrix,
         clustering_distance_rows=poisd$dd,
         clustering_distance_cols=poisd$dd,
         col=colors)
dev.off()

## PCA plot of the samples
plotPCA(rld, intgroup = c("treatment", "replicate"))

(data <- plotPCA(rld, intgroup = c("treatment", "replicate"), returnData = TRUE))


percentVar <- round(100 * attr(data, "percentVar"))
ggplot(data, aes(PC1, PC2, color=treatment, shape=replicate)) + geom_point(size=3) +
    xlab(paste0("PC1: ",percentVar[1],"% variance")) +
        ylab(paste0("PC2: ",percentVar[2],"% variance")) +
            coord_fixed()
ggsave("Standard_PCA.png")

## Making fviz_pca
rv <- genefilter::rowVars(assay(rld))
select <- order(rv, decreasing = TRUE)[seq_len(min(500, length(rv)))]
pca <- prcomp(t(assay(rld)[select, ]))

p <- fviz_pca_ind(pca, label = "all", invisible="none", alpha.var = "contrib",
                  habillage = as.character(colData(rld[select, ])$treatment), addEllipses = T)
ggsave("Standard_PCA_treatment_fviz_pca_ind.png")

p <- fviz_pca_ind(pca, label = "all", invisible="none", alpha.var = "contrib", habillage = as.character(s2c$replicate), addEllipses = T)
ggsave("Standard_PCA_replicate_fviz_pca_ind.png")

## MDS plot of the samples
mdsData <- data.frame(cmdscale(sampleDistMatrix))
mds <- cbind(mdsData, as.data.frame(colData(rld)))
ggplot(mds, aes(X1,X2,color=treatment,shape=replicate)) + geom_point(size=3) +
    coord_fixed()
ggsave("Standard_MDS.png")


## Poisson Distance MDS plot
mdsPoisData <- data.frame(cmdscale(samplePoisDistMatrix))
mdsPois <- cbind(mdsPoisData, as.data.frame(colData(dds)))
ggplot(mdsPois, aes(X1,X2,color=treatment,shape=replicate)) + geom_point(size=3) +
    coord_fixed()
ggsave("Standard_Poisson_MDS.png")

#################### DIFFERENTIAL EXPRESSION ANALYSIS ####################
threads <- 4
register(MulticoreParam(workers = threads))
(dds <- DESeqDataSetFromTximport(txi = txi, colData = sampleTable, design =  ~ treatment))
dds <- DESeq(dds, parallel = TRUE)
res <- results(dds, alpha = 0.05, parallel = TRUE)
res$symbol <- gene.symbols[gene.symbols$ens_gene %in% rownames(res), ]$ext_gene
mcols(res)$description[7] <- "Gene Symbol"
res.Ordered <- res[order(res$padj), ]
resOrderedDF <- as.data.frame(res.Ordered)
resOrderedDF$genes <- rownames(resOrderedDF)
resOrderedDF <- resOrderedDF[, c("symbol", setdiff(names(resOrderedDF), "symbol"))]
resOrderedDF <- resOrderedDF[, c("genes", setdiff(names(resOrderedDF), "genes"))]
## write.csv(resOrderedDF, file = file.path(results.dir, paste0("DESeq2_comparisons_results.csv")))

data <- plotCounts(dds, which.min(res$padj),
                   intgroup=c("timepoint","treatment"), returnData=TRUE)
ggplot(data, aes(x=timepoint, y=count, color=treatment, group=treatment)) +
    geom_point() + stat_smooth(se=FALSE,method="loss") +  scale_y_log10()
ggsave("Timecourse_comparisons_counts_over_time.png")

resultsNames(dds)

#################### DIFFERENTIAL EXPRESSION WALD TEST VECTORIZATION ####################
threads <- 4
register(MulticoreParam(workers = threads))

dds <- DESeqDataSetFromTximport(txi = txi, colData = sampleTable, design = ~ treatment)
dds <- DESeq(dds, test = c("Wald"), parallel = TRUE)

baseMeanPerSample <- sapply(levels(dds$treatment), function(lvl) { rowMeans ( counts(dds, normalized = TRUE)[, dds$treatment == lvl] ) } )

treatments <- unique(as.character(s2c$treatment))
tables <- makeResultsTables(treatments, dds, 4, gene.symbols)

b <- unlist(tables, recursive = FALSE)
names(b) <- gsub("([A-Za-z])\\.([A-Za-z])", "\\1.vs.\\2", names(b))

dired <- "Todd_genes"
dir.create(dired)
lapply(b, function(x) {
    resOrdered <- x[grep("AT4G18480|AT5G53200|AT5G61850|AT1G65480", rownames(x)), ]
    name <- mcols(x, use.names = TRUE)$description[4]
    name <- gsub(" ", "_", name)
    name <- gsub("statistic", "test", name)
    name <- gsub(":", "", name)
    resOrderedDF <- as.data.frame(resOrdered)
    resOrderedDF$genes <- rownames(resOrderedDF)
    resOrderedDF <- resOrderedDF[, c("symbol", setdiff(names(resOrderedDF), "symbol"))]
    resOrderedDF <- resOrderedDF[, c("genes", setdiff(names(resOrderedDF), "genes"))]
    write.csv(resOrderedDF, file = file.path(dired, paste0(name, ".csv")), row.names = FALSE)
}
)

## Largest baseMean which is...RUBISCO! It is working as expected
## res[which.max(res$baseMean), ]

## ## makes an "MA-Plot" which is a scatterplot of the log fold change (y) vs mean of normalized counts (x)
## plotMA(res, main="DESeq2", alpha = 0.05)
## plotCounts(dds, gene=which.min(res$padj), intgroup="treatment")

## ## Cluster significant genes by their profiles
## betas <- coef(dds)
## colnames(betas)

## topGenes <- head(order(res$padj), 20)
## mat <- betas[topGenes, -c(1,2)]
## thr <- 3
## mat[mat < -thr] <- -thr
## mat[mat > thr] <- thr

## png(filename = "Cluster_signif_genes_profiles_heatmap.png", width = 480*2, height = 480*2, res = 100)
## pheatmap(mat, breaks=seq(from=-thr, to=thr, length=101),
##          cluster_col=FALSE)
## dev.off()


## Creation of TPM csvs for Todd
indices <- unique(paste0(sampleTable$treatment,"-.*-",sampleTable$timepoint))
txi.agg.abundance <- do.call(cbind, lapply(indices, function(i) { rowMeans(txi$abundance[, grep(i, colnames(txi$abundance), val = T)]) }))
colnames(txi.agg.abundance) <- gsub("-.*", "", indices, fixed = TRUE)
## txi.agg.abundance <- do.call(cbind, lapply(ind, function(i) rowMeans(txi.reorder$abundance[, i])))
## txi.agg.length <- do.call(cbind, lapply(ind, function(i) rowMeans(txi.reorder$length[, i])))
## txi.agg.counts <- do.call(cbind, lapply(ind, function(i) rowMeans(txi.reorder$counts[, i])))
## txi.agg <- list(abundance = txi.agg.abundance, counts = txi.agg.counts, length = txi.agg.length)

## txi.agg.name <- lapply(txi.agg, function(x) { colnames(x) <- new.names;return(x) })
write.csv(txi.agg.abundance, file.path(results.dir, "Per_gene_abundance_counts_length.csv"))
