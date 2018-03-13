source("https://bioconductor.org/biocLite.R")
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


timepoints <- c(0, 24, 48)
labels <- c("A", "B", "C", "D", "E")
treatments <- c("No_Tx", "IAA_plus", "IAA_ulR1", "IAA_ulR2", "PBS_ulR")
replicates <- c(1:3)

label <- as.character(sapply(labels, rep, 9))
treatment <- as.character(sapply(treatments, rep, 9))
timepoint <- rep(timepoints, 15)
replicate <- rep(as.numeric(sapply(replicates, rep, 3)), 5)

s2c <- data.frame(
    label = label,
    treatment = treatment,
    timepoint = timepoint,
    replicate = replicate
    )

## Drawing a tree of the experiment
s2c$pathString <- paste("Arabidopsis_thaliana", s2c$treatment, s2c$timepoint, s2c$replicate, sep="/")
experiment <- as.Node(s2c)
## plot(experiment)


files <- sapply(dir("results"), function(id) file.path("results", id, "kallisto", "abundance.tsv"))
files <- unname(files[-grep("Undetermined", files)])
names(files) <- paste0(s2c$treatment,"-",s2c$replicate,"-",s2c$timepoint)

## Adding Arabidopsis Thaliana genes from biomaRt
txdb <- org.At.tair.db
mart <- biomaRt::useMart(biomart = "plants_mart",
                         dataset = "athaliana_eg_gene",
                         host = 'plants.ensembl.org')

t2g <- biomaRt::getBM(attributes = c("ensembl_transcript_id", "ensembl_gene_id",
                          "external_gene_id"), mart = mart)
## t2g <- biomaRt::getBM(attributes = c("ensembl_transcript_id", "ensembl_gene_id",
##                           "external_gene_id", "go_accession"), mart = mart)

t2g <- dplyr::rename(t2g, target_id = ensembl_transcript_id,
                     ens_gene = ensembl_gene_id, ext_gene = external_gene_id)

t2g <- t2g[order(t2g$ens_gene), ]

gene.symbols <- t2g[!duplicated(t2g$ens_gene), ]

## Making the same with the Arabidopsis GFF object
athal <- loadDb("Arabidopsis_thaliana.sqlite")
k <- keys(athal, keytype = "GENEID")
athal.t2g <- select(athal, keys = k, keytype = "GENEID", columns = "TXNAME")
athal.t2g <- athal.t2g[, 2:1]
athal.t2g <- dplyr::rename(athal.t2g, target_id = TXNAME, ens_gene = GENEID)
athal.t2g <- athal.t2g[order(athal.t2g$ens_gene), ]
athal.gene.symbols <- athal.t2g[!duplicated(t2g$ens_gene), ]

                       
## Import transcript-level estimates
txi <- tximport(files, type = "kallisto", tx2gene = t2g, reader = read_tsv)

sampleTable <- s2c
sampleTable[] <- lapply(sampleTable, factor)
sampleTable$treatment <- relevel(sampleTable$treatment, "No_Tx")
rownames(sampleTable) <- colnames(txi$counts)
sampleTable$timepoint <- factor(sampleTable$timepoint)

(dds <- DESeqDataSetFromTximport(txi = txi, colData = sampleTable, design =  ~ treatment))


## We begin visualizing the entire pipeline with RLD to see it, but we differentially express on raw samples.
dds <- dds[ rowSums(counts(dds)) > 1, ]

rld <- rlog(dds, blind=FALSE)

par( mfrow = c( 1, 2 ) )
dds <- estimateSizeFactors(dds)

## Scatterplot of transformed counts from two samples. Shown are scatterplots using the log2
## transform of normalized counts (left side) and using the rlog (right side).
## We can see how genes with low counts (bottom left-hand corner) seem to be excessively variable
## on the ordinary logarithmic scale, while the rlog transform compresses differences
## for the low count genes for which the data provide little information about differential expression.
plot(log2(counts(dds, normalized=TRUE)[,c(1,10)] + 1),
     pch=16, cex=0.3)
plot(assay(rld)[,c(1,10)],
          pch=16, cex=0.3)

## Measuring similarity between samples
sampleDists <- dist(t(assay(rld)))

## Normal distance heatmap
sampleDistMatrix <- as.matrix(sampleDists)
rownames(sampleDistMatrix) <- paste0(rld$treatment,"-",rld$replicate,"-",rld$timepoint)
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
rownames(samplePoisDistMatrix) <- paste0(rld$treatment,"-",rld$replicate,"-",rld$timepoint)
colnames(samplePoisDistMatrix) <- NULL

png(filename = "Poisson_heatmap.png", width = 480*2, height = 480*2, res = 100)
pheatmap(samplePoisDistMatrix,
         clustering_distance_rows=poisd$dd,
         clustering_distance_cols=poisd$dd,
         col=colors)
dev.off()

## PCA plot of the samples
plotPCA(rld, intgroup = c("treatment", "timepoint", "replicate"))

(data <- plotPCA(rld, intgroup = c("treatment", "timepoint", "replicate"), returnData = TRUE))

percentVar <- round(100 * attr(data, "percentVar"))
ggplot(data, aes(PC1, PC2, color=treatment, shape=timepoint)) + geom_point(size=3) +
    xlab(paste0("PC1: ",percentVar[1],"% variance")) +
        ylab(paste0("PC2: ",percentVar[2],"% variance")) +
            coord_fixed()

## MDS plot of the samples
mdsData <- data.frame(cmdscale(sampleDistMatrix))
mds <- cbind(mdsData, as.data.frame(colData(rld)))
ggplot(mds, aes(X1,X2,color=timepoint,shape=treatment)) + geom_point(size=3) +
      coord_fixed()


## Poisson Distance MDS plot
mdsPoisData <- data.frame(cmdscale(samplePoisDistMatrix))
mdsPois <- cbind(mdsPoisData, as.data.frame(colData(dds)))
ggplot(mdsPois, aes(X1,X2,color=timepoint,shape=treatment)) + geom_point(size=3) +
      coord_fixed()


#################### BEGIN DIFFERENTIAL EXPRESSION ANALYSIS ####################
dds <- DESeq(dds, parallel = TRUE, BPPARAM = MulticoreParam(workers = 20))
## dds <- DESeq(dds)
(res <- results(dds, alpha = 0.05, parallel = TRUE, BPPARAM = MulticoreParam(workers = 4)))
mcols(res, use.names = TRUE)
summary(res)
table(res$padj < 0.05)

## Treatment A vs B
(res <- results(dds, alpha = 0.05, contrast=c("treatment", "A", "B"), parallel = TRUE, BPPARAM = MulticoreParam(workers = 4)))
mcols(res, use.names = TRUE)
summary(res)
table(res$padj < 0.05)p

res$symbol <- gene.symbols[gene.symbols$ens_gene %in% rownames(res), ]$ext_gene
## res$symbol <- gene.symbols$ext_gene[1:nrow(res)]

## Treatment comparisons:
combinations <- combn(treatments, m =2)
sapply(1:ncol(combinations),
       function(col.i) {
           trt1 <- combinations[1, col.i]
           trt2 <- combinations[2, col.i]
           print(paste0("We are comparing: ",trt1, " vs ", trt2))
           res <- results(dds, alpha = 0.05, contrast=c("treatment", trt1, trt2), parallel = TRUE, BPPARAM = MulticoreParam(workers = 4))
           res$sybol <- t2g$ext_gene[1:nrow(res)]
           resOrdered <- res[order(res$padj), ]
           resOrderedDF <- as.data.frame(resOrdered)
           write.csv(resOrderedDF, file = paste0(trt1, "_vs_", trt2, "_results.csv")) 
       }
       )


###### TIME SERIES VERSION ######
(ddsTC <- DESeqDataSetFromTximport(txi = txi, colData = sampleTable, design =  ~ treatment + timepoint + treatment:timepoint))
## We begin visualizing the entire pipeline with RLD to see it, but we differentially express on raw samples.
ddsTC <- ddsTC[ rowSums(counts(ddsTC)) > 1, ]

rld <- rlog(ddsTC, blind=FALSE)

ddsTC <- estimateSizeFactors(ddsTC)

## Scatterplot of transformed counts from two samples. Shown are scatterplots using the log2
## transform of normalized counts (left side) and using the rlog (right side).
## We can see how genes with low counts (bottom left-hand corner) seem to be excessively variable
## on the ordinary logarithmic scale, while the rlog transform compresses differences
## for the low count genes for which the data provide little information about differential expression.
png(filename = "rlog_comparison_two_samples.png", width = 480*2, height = 480*2, res = 100)
par( mfrow = c( 1, 2 ) )
plot(log2(counts(ddsTC, normalized=TRUE)[,c(1,10)] + 1),
     pch=16, cex=0.3)
plot(assay(rld)[,c(1,10)],
     pch=16, cex=0.3)
dev.off()

## Measuring similarity between samples
sampleDists <- dist(t(assay(rld)))

## Normal distance heatmap
sampleDistMatrix <- as.matrix(sampleDists)
rownames(sampleDistMatrix) <- paste0(rld$treatment,"-",rld$replicate,"-",rld$timepoint)
colnames(sampleDistMatrix) <- NULL
colors <- colorRampPalette(rev(brewer.pal(9, "Blues")) )(255)

png(filename = "Standard_heatmap.png", width = 480*2, height = 480*2, res = 100)
pheatmap(sampleDistMatrix,
         clustering_distance_rows=sampleDists,
         clustering_distance_cols=sampleDists,
         col=colors)
dev.off()

## Poisson Distance heatmap
poisd <- PoissonDistance(t(counts(ddsTC)))

samplePoisDistMatrix <- as.matrix( poisd$dd )
rownames(samplePoisDistMatrix) <- paste0(rld$treatment,"-",rld$replicate,"-",rld$timepoint)
colnames(samplePoisDistMatrix) <- NULL

png(filename = "Poisson_heatmap.png", width = 480*2, height = 480*2, res = 100)
pheatmap(samplePoisDistMatrix,
         clustering_distance_rows=poisd$dd,
         clustering_distance_cols=poisd$dd,
         col=colors)
dev.off()

## PCA plot of the samples
plotPCA(rld, intgroup = c("treatment", "timepoint", "replicate"))

(data <- plotPCA(rld, intgroup = c("treatment", "timepoint", "replicate"), returnData = TRUE))


percentVar <- round(100 * attr(data, "percentVar"))
ggplot(data, aes(PC1, PC2, color=treatment, shape=timepoint)) + geom_point(size=3) +
    xlab(paste0("PC1: ",percentVar[1],"% variance")) +
        ylab(paste0("PC2: ",percentVar[2],"% variance")) +
            coord_fixed()
ggsave("Timecourse_PCA.png")

## Making fviz_pca
rv <- genefilter::rowVars(assay(rld))
select <- order(rv, decreasing = TRUE)[seq_len(min(500, length(rv)))]
pca <- prcomp(t(assay(rld)[select, ]))

p <- fviz_pca_ind(pca, label = "all", invisible="none", alpha.var = "contrib", habillage = treatment, addEllipses = T)
ggsave("Timecourse_PCA_treatment_fviz_pca_ind.png")
p <- fviz_pca_ind(pca, label = "all", invisible="none", alpha.var = "contrib", habillage = timepoint, addEllipses = T)
ggsave("Timecourse_PCA_timepoint_fviz_pca_ind.png")

## MDS plot of the samples
mdsData <- data.frame(cmdscale(sampleDistMatrix))
mds <- cbind(mdsData, as.data.frame(colData(rld)))
ggplot(mds, aes(X1,X2,color=treatment,shape=timepoint)) + geom_point(size=3) +
    coord_fixed()
ggsave("Timecourse_MDS.png")


## Poisson Distance MDS plot
mdsPoisData <- data.frame(cmdscale(samplePoisDistMatrix))
mdsPois <- cbind(mdsPoisData, as.data.frame(colData(ddsTC)))
ggplot(mdsPois, aes(X1,X2,color=treatment,shape=timepoint)) + geom_point(size=3) +
    coord_fixed()
ggsave("Timecourse_Poisson_MDS.png")

#################### TIME COURSE DIFFERENTIAL EXPRESSION ANALYSIS ####################
threads <- 4
register(MulticoreParam(workers = threads))
(ddsTC <- DESeqDataSetFromTximport(txi = txi, colData = sampleTable, design =  ~ treatment + timepoint + treatment:timepoint))
ddsTC <- DESeq(ddsTC, test="LRT", reduced = ~ treatment + timepoint, parallel = TRUE)
resTC <- results(ddsTC, alpha = 0.05, parallel = TRUE)
resTC$symbol <- gene.symbols[gene.symbols$ens_gene %in% rownames(resTC), ]$ext_gene
mcols(resTC)$description[7] <- "Gene Symbol"
resTC.Ordered <- resTC[order(resTC$padj), ]
resTCOrderedDF <- as.data.frame(resTC.Ordered)
resTCOrderedDF$genes <- rownames(resTCOrderedDF)
resTCOrderedDF <- resTCOrderedDF[, c("symbol", setdiff(names(resTCOrderedDF), "symbol"))]
resTCOrderedDF <- resTCOrderedDF[, c("genes", setdiff(names(resTCOrderedDF), "genes"))]
write.csv(resTCOrderedDF, file = paste0("Timecourse_comparisons_results.csv"))

## HTML Report
desReport <- HTMLReport(shortName="Mockler_Lab_RNAseq_analysis_with_DESeq2", title="Mockler Lab RNA-seq analysis",
                        reportDirectory="./reports")
publish(resTCOrderedDF, desReport)
url <- finish(desReport)
browseURL(url)

## regionReport
dir.create("regionReport")
report <- DESeq2Report(ddsTC, project = "Mockler_Lab_RNAseq_analysis_with_DESeq2",
                       intgroup = c("treatment", "timepoint"), res = resTC, outdir = "regionReport",
                       output = 'index', theme = theme_bw(), searchURL="https://www.arabidopsis.org/servlets/Search?type=general&search_action=detail&method=1&show_obsolete=F&sub_type=gene&SEARCH_EXACT=4&SEARCH_CONTAINS=1&name=")

data <- plotCounts(ddsTC, which.min(resTC$padj),
                   intgroup=c("timepoint","treatment"), returnData=TRUE)
ggplot(data, aes(x=timepoint, y=count, color=treatment, group=treatment)) +
    geom_point() + stat_smooth(se=FALSE,method="loss") +  scale_y_log10()
ggsave("Timecourse_comparisons_counts_over_time.png")

resultsNames(ddsTC)

## Largest baseMean which is...RUBISCO! It is working as expected
resTC[which.max(resTC$baseMean), ]

## makes an "MA-Plot" which is a scatterplot of the log fold change (y) vs mean of normalized counts (x)
plotMA(resTC, main="DESeq2", alpha = 0.05)
plotCounts(ddsTC, gene=which.min(resTC$padj), intgroup="treatment")

## Cluster significant genes by their profiles
betas <- coef(ddsTC)
colnames(betas)

topGenes <- head(order(resTC$padj), 20)
mat <- betas[topGenes, -c(1,2)]
thr <- 3
mat[mat < -thr] <- -thr
mat[mat > thr] <- thr

png(filename = "Cluster_signif_genes_profiles_heatmap.png", width = 480*2, height = 480*2, res = 100)
pheatmap(mat, breaks=seq(from=-thr, to=thr, length=101),
         cluster_col=FALSE)
dev.off()

## Beginning of time series is at Line 181

lapply(treatments,
       function(y) {
           sampleTable <- s2c
           sampleTable[] <- lapply(sampleTable, factor)
           sampleTable$treatment <- relevel(sampleTable$treatment, y)
           rownames(sampleTable) <- colnames(txi$counts)
           sampleTable$timepoint <- factor(sampleTable$timepoint)
           threads <- 4
           register(MulticoreParam(workers = threads))
           ddsTC <- DESeqDataSetFromTximport(txi = txi, colData = sampleTable, design =  ~ treatment + timepoint + treatment:timepoint)
           ddsTC <- DESeq(ddsTC, test="LRT", reduced = ~ treatment + timepoint, parallel = TRUE)
           lapply(resultsNames(ddsTC),
                  function(x) {
                      resTC <- results(ddsTC, alpha = 0.05, parallel = TRUE, name = x)
                      resTC$symbol <- gene.symbols[gene.symbols$ens_gene %in% rownames(resTC), ]$ext_gene
                      mcols(resTC)$description[7] <- "Gene Symbol"
                      resTC.Ordered <- resTC[order(resTC$padj), ]
                      print(summary(resTC.Ordered))
                      resTCOrderedDF <- as.data.frame(resTC.Ordered)
                      resTCOrderedDF$genes <- rownames(resTCOrderedDF)
                      resTCOrderedDF <- resTCOrderedDF[, c("symbol", setdiff(names(resTCOrderedDF), "symbol"))]
                      resTCOrderedDF <- resTCOrderedDF[, c("genes", setdiff(names(resTCOrderedDF), "genes"))]                      
                      write.csv(resTCOrderedDF, file = paste0("Ref_", y, "_", x, "_comparisons_results.csv"), row.names = FALSE)
                  }
                  )
       }
       )

makeResultsTables <- function(treatments = treatments, sampleTable = sampleTable, txi = txi, threads = 4, gene.symbols = gene.symbols) {
    lapply(treatments,
           function(y) {
               sampleTable <- s2c
               sampleTable[] <- lapply(sampleTable, factor)
               sampleTable$treatment <- relevel(sampleTable$treatment, y)
               rownames(sampleTable) <- colnames(txi$counts)
               sampleTable$timepoint <- factor(sampleTable$timepoint)
               register(MulticoreParam(workers = threads))
               ddsTC <- DESeqDataSetFromTximport(txi = txi, colData = sampleTable, design =  ~ treatment + timepoint + treatment:timepoint)
               ddsTC <- DESeq(ddsTC, test="LRT", reduced = ~ treatment + timepoint, parallel = TRUE)
               dired <- paste0("Ref_", y)
               dir.create(dired)               
               ## Plots can be made from this point forward
               rld <- rlog(ddsTC, blind=FALSE)
               ddsTC <- estimateSizeFactors(ddsTC)
               ## Measuring similarity between samples
               sampleDists <- dist(t(assay(rld)))

               ## Normal distance heatmap
               sampleDistMatrix <- as.matrix(sampleDists)
               rownames(sampleDistMatrix) <- paste0(rld$treatment,"-",rld$replicate,"-",rld$timepoint)
               colnames(sampleDistMatrix) <- NULL
               colors <- colorRampPalette(rev(brewer.pal(9, "Blues")) )(255)

               png(filename = file.path(dired, "Standard_heatmap.png"), width = 480*2, height = 480*2, res = 100)
               pheatmap(sampleDistMatrix,
                        clustering_distance_rows=sampleDists,
                        clustering_distance_cols=sampleDists,
                        col=colors)
               dev.off()

               ## Poisson Distance heatmap
               poisd <- PoissonDistance(t(counts(ddsTC)))

               samplePoisDistMatrix <- as.matrix( poisd$dd )
               rownames(samplePoisDistMatrix) <- paste0(rld$treatment,"-",rld$replicate,"-",rld$timepoint)
               colnames(samplePoisDistMatrix) <- NULL

               png(filename = file.path(dired, "Poisson_heatmap.png"), width = 480*2, height = 480*2, res = 100)
               pheatmap(samplePoisDistMatrix,
                        clustering_distance_rows=poisd$dd,
                        clustering_distance_cols=poisd$dd,
                        col=colors)
               dev.off()

               ## PCA plot of the samples
               data <- plotPCA(rld, intgroup = c("treatment", "timepoint", "replicate"), returnData = TRUE)
               percentVar <- round(100 * attr(data, "percentVar"))
               ggplot(data, aes(PC1, PC2, color=treatment, shape=timepoint)) + geom_point(size=3) +
                   xlab(paste0("PC1: ",percentVar[1],"% variance")) +
                       ylab(paste0("PC2: ",percentVar[2],"% variance")) +
                           coord_fixed()
               ggsave(file.path(dired, "Timecourse_PCA.png"))

               ## Making fviz_pca
               rv <- genefilter::rowVars(assay(rld))
               select <- order(rv, decreasing = TRUE)[seq_len(min(500, length(rv)))]
               pca <- prcomp(t(assay(rld)[select, ]))

               p <- fviz_pca_ind(pca, label = "all", invisible="none", alpha.var = "contrib", habillage = treatment, addEllipses = T)
               ggsave(file.path(dired, "Timecourse_PCA_treatment_fviz_pca_ind.png"))
               p <- fviz_pca_ind(pca, label = "all", invisible="none", alpha.var = "contrib", habillage = timepoint, addEllipses = T)
               ggsave(file.path(dired, "Timecourse_PCA_timepoint_fviz_pca_ind.png"))

               ## MDS plot of the samples
               mdsData <- data.frame(cmdscale(sampleDistMatrix))
               mds <- cbind(mdsData, as.data.frame(colData(rld)))
               ggplot(mds, aes(X1,X2,color=treatment,shape=timepoint)) + geom_point(size=3) +
                   coord_fixed()
               ggsave(file.path(dired, "Timecourse_MDS.png"))

               ## Poisson Distance MDS plot
               mdsPoisData <- data.frame(cmdscale(samplePoisDistMatrix))
               mdsPois <- cbind(mdsPoisData, as.data.frame(colData(ddsTC)))
               ggplot(mdsPois, aes(X1,X2,color=treatment,shape=timepoint)) + geom_point(size=3) +
                   coord_fixed()
               ggsave(file.path(dired, "Timecourse_Poisson_MDS.png"))

               data <- plotCounts(ddsTC, which.min(resTC$padj),
                                  intgroup=c("timepoint","treatment"), returnData=TRUE)
               ggplot(data, aes(x=timepoint, y=count, color=treatment, group=treatment)) +
                   geom_point() + stat_smooth(se=FALSE,method="loss") +  scale_y_log10()
               ggsave(file.path(dired, "Timecourse_comparisons_counts_over_time.png"))
               lapply(resultsNames(ddsTC),
                      function(x) {
                          resTC <- results(ddsTC, alpha = 0.05, parallel = TRUE, name = x)
                          resTC$symbol <- gene.symbols[gene.symbols$ens_gene %in% rownames(resTC), ]$ext_gene
                          mcols(resTC)$description[7] <- "Gene Symbol"
                          resTC.Ordered <- resTC[order(resTC$padj), ]
                          sink(paste0(dired, "_", "summary_", x,".txt"))
                          print(summary(resTC.Ordered))
                          sink()
                          resTCOrderedDF <- as.data.frame(resTC.Ordered)
                          resTCOrderedDF$genes <- rownames(resTCOrderedDF)
                          resTCOrderedDF <- resTCOrderedDF[, c("symbol", setdiff(names(resTCOrderedDF), "symbol"))]
                          resTCOrderedDF <- resTCOrderedDF[, c("genes", setdiff(names(resTCOrderedDF), "genes"))]
                          write.csv(resTCOrderedDF, file = file.path(dired, paste0(dired, "_", x, "_comparisons_results.csv")), row.names = FALSE)
                      }
                      )
           }
           )
}


## TESTING

indices <- c(grep("-0$", colnames(txi$abundance)),grep("-24$", colnames(txi$abundance)), grep("-48$", colnames(txi$abundance)))
txi.reorder <- lapply(txi[1:3], function(x) { x[, indices] })
new.names <- colnames(txi.reorder$abundance)
new.names <- unique(gsub("-1|-3|-2(?=-)", "", new.names, perl = TRUE))
## new.names <- gsub("-1|", "", new.names)

n <- 1:ncol(txi.reorder$counts)
ind <- data.frame(matrix(c(n, rep(NA, 3 - ncol(txi.reorder$counts) %% 3)), byrow=F, nrow=3))
nonna <- sapply(ind, function(x) all(!is.na(x)))
ind <- ind[, nonna]

txi.agg.abundance <- do.call(cbind, lapply(ind, function(i) rowMeans(txi.reorder$abundance[, i])))
txi.agg.length <- do.call(cbind, lapply(ind, function(i) rowMeans(txi.reorder$length[, i])))
txi.agg.counts <- do.call(cbind, lapply(ind, function(i) rowMeans(txi.reorder$counts[, i])))
txi.agg <- list(abundance = txi.agg.abundance, counts = txi.agg.counts, length = txi.agg.length)

txi.agg.name <- lapply(txi.agg, function(x) { colnames(x) <- new.names;return(x) })
write.csv(txi.agg.name, "Per_gene_abundance_counts_length.csv")

txi.agg.melt.final <- merge_recurse(
    lapply(names(txi.agg.name),
           function(x) {
               b <- melt(txi.agg.name[[x]])
               colnames(b) <- c("gene", "treatment", x); return(b)
           }
           )
)

timepoint <- sapply(strsplit(as.character(txi.agg.melt.final[, 2]), '-'), '[[', 2)
txi.agg.melt.final[, "timepoint"] <- timepoint
txi.agg.melt.final[, "treatment"] <- gsub("-\\d+$", "",txi.agg.melt.final$treatment, perl=T)
txi.agg.melt.final <- moveMe(txi.agg.melt.final, "timepoint", "after", "treatment")

write.csv(txi.agg.melt.final, "Per_gene_abundance_counts_length_df.csv", row.names = FALSE)

moveMe <- function(data, tomove, where = "last", ba = NULL) {
    temp <- setdiff(names(data), tomove)
    x <- switch(
        where,
        first = data[c(tomove, temp)],
        last = data[c(temp, tomove)],
        before = {
            if (is.null(ba)) stop("must specify ba column")
            if (length(ba) > 1) stop("ba must be a single character string")
            data[append(temp, values = tomove, after = (match(ba, temp)-1))]
        },
        after = {
            if (is.null(ba)) stop("must specify ba column")
            if (length(ba) > 1) stop("ba must be a single character string")
            data[append(temp, values = tomove, after = (match(ba, temp)))]
        })
    x
}


txi.melt <- merge_recurse(
    lapply(names(txi)[1:3],
           function(x) {
               b <- melt(txi[[x]])
               colnames(b) <- c("gene", "treatment", x); return(b)
           }
           )
)

timepoint <- sapply(strsplit(as.character(txi.melt[, 2]), '-'), '[[', 3)
replicate <- sapply(strsplit(as.character(txi.melt[, 2]), '-'), '[[', 2)
txi.melt[, "timepoint"] <- timepoint
txi.melt[, "replicate"] <- replicate
txi.melt[, "treatment"] <- gsub("-\\d-\\d+$", "",txi.melt$treatment, perl=T)
txi.melt <- moveMe(txi.melt, "timepoint", "after", "treatment")
txi.melt <- moveMe(txi.melt, "replicate", "after", "timepoint")

write.csv(txi.melt, file = "Per_replicate_gene_abundance_counts_length_df.csv", row.names = FALSE)

write.csv(txi.melt[txi.melt$replicate == 1, ], file = "Per_replicate_1_gene_abundance_counts_length_df.csv")
write.csv(txi.melt[txi.melt$replicate == 2, ], file = "Per_replicate_2_gene_abundance_counts_length_df.csv")
write.csv(txi.melt[txi.melt$replicate == 3, ], file = "Per_replicate_3_gene_abundance_counts_length_df.csv")
