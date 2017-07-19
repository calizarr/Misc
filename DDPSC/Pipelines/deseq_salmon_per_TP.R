
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
## library("org.At.tair.db")
## Interactive plots and reports
library(regionReport)
library(ReportingTools)
## Tree drawing
library(treemap)
library(data.tree)
library("GenomicFeatures")
library(GO.db)
library(data.table)

## ## Using lookup table for R
## library(devtools, quietly=TRUE)
## ## source_gist("https://gist.github.com/dfalster/5589956")
## source_gist("https://gist.github.com/dfalster/5589956", filename = "addNewData.R")

## Variables
annotation.path <- "/home/clizarraga/Brachypodium_distachyon/Phytozome/v3.1/annotation/"
symbol.file <- "Bdistachyon_314_v3.1.synonym.txt"
annot.file <- "Bdistachyon_314_v3.1.gene_exons.gff3"
go.file <- "Bdistachyon_314_v3.1.annotation_info.txt"
def.file <- "Bdistachyon_314_v3.1.defline.txt"
options(mc.cores = 4)
## cl <- makePSOCKcluster(4)

## Functions
subset.txi <- function(grep.vals, txi, inv = FALSE) {
    lapply(txi, function(x) {
        if(length(x) != 1) {
            sub <- grep(grep.vals, attr(x, "dimnames")[[2]], invert = inv)
            z <- x[, sub]
            return(z)
        } else {
            return(x)
        }
    }
    )
}


## ENCODE sample name reading

TM009.planting.date <- as.Date("2015-09-08", format = "%Y-%m-%d")
TM012.planting.date <- as.Date("2015-11-17", format = "%Y-%m-%d")
TM014.planting.date <- as.Date("2016-03-22", format = "%Y-%m-%d")
encode.sample.ids <- read.csv("ENCODE_sample_IDs.csv", stringsAsFactors = FALSE)
names(encode.sample.ids) <- c("Sample.ID", "Tube.No", "Collection.Date", "Genotype", "Treatment")
JGI.data.table <- read.csv("JGI_Data_Table.csv", stringsAsFactors = FALSE)
merged.samples <- merge(JGI.data.table, encode.sample.ids, by.y = "Sample.ID", by.x = "sampleName")
merged.samples$Collection.Date <- as.Date(merged.samples$Collection.Date, format = "%m/%d/%Y")
merged.samples[merged.samples$Genotype == "Bd21-1", ]$Genotype = "Bd21-0"
## merged.samples[merged.samples$Treatment == "Drought+Recovery", ]$Treatment = "Drought"
## merged.samples[merged.samples$Treatment == "90%+Drought+Recovery", ]$Treatment = "90%"
merged.ordered <- merged.samples[order(merged.samples$Collection.Date), ]
## merged.samples[merged.samples$Treatment == "Drought+Recovery", ]$Treatment = "Drought"

## ## Making a lookup data frame
values.A <- sort(unique(merged.samples$Collection.Date[grep("A", merged.samples$sampleName)])) - TM009.planting.date
values.B <- sort(unique(merged.samples$Collection.Date[grep("B", merged.samples$sampleName)])) - TM012.planting.date
values.C <- sort(unique(merged.samples$Collection.Date[grep("C", merged.samples$sampleName)])) - TM014.planting.date
## lookup <- data.frame(
##     lookupVariable = "Collection.Date",
##     lookupValue = sort(unique(merged.samples$Collection.Date)),
##     newVariable = "DAP",
##     newValue = rep(eval(parse(text=paste0("c(",paste(values.A - TM009.planting.date, collapse = ","),")")), 3))
## )

## write.csv(lookup, file = "lookupTable.csv", row.names = FALSE)
## merged.dap <- addNewData("lookupTable.csv", merged.ordered, "DAP")

## Making lookup without the unspecified gist code
merged.dap <- merged.ordered
lookupValue <- sort(unique(merged.samples$Collection.Date))
## newValue <- rep(values.A - TM009.planting.date, 3)
newValue <- c(values.A, values.B, values.C)
merged.dap[, "DAP"] <- newValue[match(merged.ordered$Collection.Date, lookupValue)]

a <- sort(unique(merged.dap$sampleName))
b <- ifelse(grepl("A", a), 1, ifelse(grepl("B", a), 2, ifelse(grepl("C", a), 3, ifelse(grepl("D", a), 4, "NA"))))
merged.dap[, "Replicates"] <- b[match(merged.dap$sampleName, sort(unique(merged.dap$sampleName)))]
merged.dap$fileNames <- paste0(merged.dap$Genotype,"-", merged.dap$Treatment,"-",merged.dap$DAP,"-",merged.dap$Replicates)

timepoints <- merged.dap$DAP
labels <- merged.dap$sampleName
treatments <- merged.dap$Treatment
replicates <- merged.dap$Replicates
genotypes <- merged.dap$Genotype

s2c <- data.frame(
    label = as.character(labels),
    genotype = as.character(genotypes),
    treatment = as.character(treatments),
    timepoint = timepoints,
    replicate = replicates
)
s2c$label <- as.character(s2c$label)
s2c$genotype <- as.character(s2c$genotype)
s2c$treatment <- as.character(s2c$treatment)

## early.s2c <- s2c[s2c$timepoint <= 25, ]
## middle.s2c <- s2c[s2c$timepoint > 25 & s2c$timepoint < 39, ]
## late.s2c <- s2c[s2c$timepoint >= 39, ]

## s2c$pathString <- paste("Brachypodium_distachyon", s2c$genotype, s2c$treatment, s2c$timepoint, s2c$replicate, sep="/")
## experiment <- as.Node(s2c)

files <- sapply(dir("results"), function(id) file.path("results", id, "salmon", "quant.sf"))
## files <- unname(files[-grep("Undetermined", files)])
## names(files) <- paste0(s2c$genotype,"-",s2c$treatment,"-",s2c$replicate,"-",s2c$timepoint)
## s2c$fileNames <- paste0(s2c$genotype,"-", s2c$treatment,"-",s2c$timepoint,"-",s2c$replicate)
names(files) <- merged.dap$fileNames[match(names(files), gsub(".filter-RNA.fastq.gz", "", merged.dap$fileUsed, fixed = T))]

## Adding Brachypodium distachyon genes from biomaRt
## BdTxDb <- makeTxDbFromGFF(file = file.path(annotation.path, annot.file) , format = "gff3")
annot.save <- "Bdistachyon_314_v3.1.sqlite"
## saveDb(BdTxDb, file = file.path(annotation.path, annot.save))
BdTxDb <- loadDb(annot.save)
k <- keys(BdTxDb, keytype = "GENEID")
bdist.t2g <- select(BdTxDb, keys = k, keytype = "GENEID", columns = c("TXNAME"))
bdist.t2g <- bdist.t2g[, 2:1]
bdist.t2g <- dplyr::rename(bdist.t2g, target_id = TXNAME, ens_gene = GENEID)
bdist.t2g <- bdist.t2g[order(bdist.t2g$ens_gene), ]
t2g <- bdist.t2g

symbols <- read.csv(file.path(annotation.path, symbol.file), sep ="\t", header = FALSE)
names(symbols) <- c("target_id", "symbol")
bdist.merge <- merge(bdist.t2g, symbols, by = "target_id", all.x = T, sort = T)
t2g <- merge(bdist.t2g, symbols, by = "target_id", all.x = T, sort = T)
t2g[, "target_id"] <- paste0(t2g[, "target_id"], ".v3.1")
bdist.gene.symbols <- t2g[!duplicated(t2g$ens_gene), ]

## Import transcript-level estimates
txi <- tximport(files, type = "salmon", tx2gene = t2g, reader = read_tsv)

sim.res <- mclapply(sort(unique(s2c$timepoint)), function(tp) {
    print(paste0("We are now starting timepoint: ", tp))
    mclapply(sort(unique(s2c$genotype)), function(geno) {
        mclapply(txi, function(sub) {
            if(length(sub) == 1) {
                return(sub)
            }
            ## Subset by genotype
            test <- sub[, grep(geno, colnames(sub))]
            ## Subsetting by timepoint
            test <- test[, grep(paste0("-", tp, "-", "\\d$"), colnames(test))]
            ## Subsetting by each one of either 90%+Drought+Recovery or Drought+Recovery
            first <- "90%\\+Drought\\+Recovery"
            second <- "Drought\\+Recovery"
            if(any(grepl(first, colnames(test)))) {
                len <- length(grep(first, colnames(test)))
                fill <- 12 - len
                simulated <- apply(test[, grep(first, colnames(test))], 1, function(x) {
                    ## samples <- rnorm(fill, mean(x), sd(x))
                    samples <- rnbinom(fill, 12, mu = mean(x))
                    ## samples[samples < 0] <- 0
                    return(samples)
                })
                if(len < 4) {
                    ## new.fill <- 4-len
                    new.fill <- setdiff(as.character(seq(1,4)), unlist(lapply(strsplit(grep(first, colnames(test), val = T), "-"), '[', 5)))
                    new.names <- c(
                        paste0(geno, "-", "90%", "-", tp, "-", new.fill),
                        paste0(geno, "-", "Drought", "-", tp, "-", seq(1,4)),
                        paste0(geno, "-", "Recovery", "-", tp, "-", seq(1,4))
                    )
                    rownames(simulated) <- new.names
                } else {
                    new.names <- c(
                        paste0(geno, "-", "Drought", "-", tp, "-", seq(1,4)),
                        paste0(geno, "-", "Recovery", "-", tp, "-", seq(1,4))
                    )
                    rownames(simulated) <- new.names
                }
                return(t(simulated))
            } else if(any(grepl(second, colnames(test)))) {
                len <- length(grep(second, colnames(test)))
                fill <- 8 - len
                simulated <- apply(test[, grep(second, colnames(test))], 1, function(x) {
                    ## samples <- rnorm(fill, mean(x), sd(x))
                    samples <- rnbinom(fill, 8, mu = mean(x))
                    ## samples[samples < 0] <- 0
                    return(samples)
                })
                if(len < 4) {
                    ## new.fill <- 4 - len
                    new.fill <- setdiff(as.character(seq(1,4)), unlist(lapply(strsplit(grep(second, colnames(test), val = T), "-"), '[', 5)))
                    new.names <- c(
                        paste0(geno, "-", "Drought", "-", tp, "-", new.fill),
                        paste0(geno, "-", "Recovery", "-", tp, "-", seq(1,4))
                    )
                    rownames(simulated) <- new.names
                } else {
                    rownames(simulated) <- paste0(geno, "-", "Recovery", "-", tp, "-", seq(1,4))
                }
                return(t(simulated))
            }
        })
    })
})
names(sim.res) <- sort(unique(s2c$timepoint))
sim.res <- mclapply(sim.res, function(x) { names(x) <- sort(unique(s2c$genotype)); return(x) })
sim.res <- sim.res[-c(8:10)]
sim.res.unlist <- unlist(unlist(sim.res, recursive = F), recursive = F)

## Adding in the simulated replicates into the txi vector.
txi.sim <- mclapply(names(txi), function(t.name) {
    print(paste0("Starting to do: ", t.name))
    if(t.name == "countsFromAbundance") {
        return(txi[[t.name]])
    } else {
        res <- do.call(cbind, sim.res.unlist[grep(paste0(t.name, "$"), names(sim.res.unlist))])
        res <- cbind(txi[[t.name]], res)
        colnames(res) <- gsub("Drought+Recovery", "Drought", gsub("90%+Drought+Recovery", "90%", colnames(res), fixed = T), fixed = T)
        return(res)
    }
})
names(txi.sim) <- names(txi)

sampleTable <- data.frame(do.call(rbind, (strsplit(colnames(txi.sim$counts), "-"))))
names(sampleTable) <- c("geno1", "geno2", "treatment", "timepoint", "replicate")
sampleTable[, "genotype"] <- paste0(sampleTable$geno1,"-",sampleTable$geno2)
sampleTable <- sampleTable[, -c(1,2)]
sampleTable <- sampleTable[, c(4, 1, 2, 3)]
sampleTable[] <- lapply(sampleTable, factor)
sampleTable$treatment <- relevel(sampleTable$treatment, "90%")
sampleTable$genotype <- relevel(sampleTable$genotype, "Bd21-0")
rownames(sampleTable) <- colnames(txi.sim$counts)
sampleTable$group <- relevel(factor(paste0(sampleTable$genotype,".",sampleTable$treatment)), "Bd21-0.90%")

## Subsetting sampleTable
sampleTable.sub <- mclapply(levels(sampleTable$timepoint), function(tp) {
    res <- sampleTable[sampleTable[, "timepoint"] == tp, ]
    res <- droplevels(res)
    treatment.res <- Reduce(intersect, lapply(split(res, res$genotype), function(x) { levels(droplevels(x$treatment)) }))
    res <- res[res$treatment %in% treatment.res, ]
    res <- droplevels(res)
    genotype.res <- Reduce(intersect, lapply(split(res, res$treatment), function(x) { levels(droplevels(x$genotype)) }))
    res <- res[res$genotype %in% genotype.res, ]
    res <- droplevels(res)
    return(res)
})
names(sampleTable.sub) <- levels(sampleTable$timepoint)

## Creating sampleTable removing all nonexisting treatments then genotypes per timepoint
sampleTable <- do.call(rbind, sampleTable.sub)
rownames(sampleTable) <- gsub("^\\d\\d\\.", "",  rownames(sampleTable))

## Splitting up the txi and sampleTable into timepoints
times <- paste0("-", levels(sampleTable$timepoint), "-")
times.txi <- mclapply(times, function(x) { subset.txi(x, txi.sim) })
names(times.txi) <- levels(sampleTable$timepoint)
txi.sub <- times.txi

txi.sub <- mclapply(names(txi.sub), function(time.seg) {
    rows.need <- colnames(txi.sub[[time.seg]]$counts)[colnames(txi.sub[[time.seg]]$counts) %in% rownames(sampleTable.sub[[time.seg]])]
    indices <- match(rows.need, colnames(txi.sub[[time.seg]]$counts))
    res <- lapply(txi.sub[[time.seg]], function(x) { if (length(x) != 1) {x[, indices]} else { x } })
    names(res) <- names(txi.sub[[time.seg]])
    return(res)
})
names(txi.sub) <- levels(sampleTable$timepoint)

formula.des <- "~ genotype + treatment + genotype:treatment"
ddsTC <- lapply(names(txi.sub), function(group) {
    print(group)
    DESeqDataSetFromTximport(txi = txi.sub[[group]], colData = sampleTable.sub[[group]], design = formula(formula.des))
})
## names(ddsTC) <- names(txi.sub)

group <- "Bd1.22.50%"
samps <- sampleTable.sub[[group]]
samps$group <- paste0(samps$genotype,".", samps$treatment)

test <- lapply(split(samps, samps$group), function(x) {
    if(length(sort(unique(as.character(x$timepoint)))) == length(levels(samps$timepoint))) {
        return(unique(x$group))
    }
}
)

test.1 <- sapply(split(samps, samps$group), function(x) { as.character(levels(samps$timepoint)) %in% as.character(sort(unique(x$timepoint))) })
test.2 <- lapply(split(samps, samps$group), function(x) { sort(unique(x$timepoint)) })
ret.null <- lapply(sort(unique(samps$group)), function(x) { print(x);print(test.1[, x]);print(as.character(test.2[[x]]));return(NULL) })

###### TIME SERIES VERSION ######
## We begin visualizing the entire pipeline with RLD to see it, but we differentially express on raw samples.
## ddsTC <- list(early = early.ddsTC, middle = middle.ddsTC, late = late.ddsTC)

ddsTC <- lapply(ddsTC, function(seg.time) {
    # early.ddsTC <- early.ddsTC[ rowSums(counts(early.ddsTC)) > 1, ]
    seg.time[rowSums(counts(seg.time)) > 1, ]
})

rldTC <- lapply(ddsTC, function(seg.time) {
    # early.rldTC <- rlog(early.ddsTC, blind = FALSE)
    rlog(seg.time, blind = FALSE)
})

ptm <- proc.time()
vsdTC <- lapply(ddsTC, function(seg.time) {
    vst(seg.time, blind = FALSE)
})
proc.time() - ptm

ptm <- proc.time()
vsdTC <- mclapply(ddsTC, function(seg.time) {
    vst(seg.time, blind = FALSE)
}, mc.cores = 4)
proc.time() - ptm


ddsTC <- lapply(ddsTC, function(seg.time) {
    # early.ddsTC <- estimateSizeFactors(early.ddsTC)
    estimateSizeFactors(seg.time)
})

## Scatterplot of transformed counts from two samples. Shown are scatterplots using the log2
## transform of normalized counts (left side) and using the rlog (right side).
## We can see how genes with low counts (bottom left-hand corner) seem to be excessively variable
## on the ordinary logarithmic scale, while the rlog transform compresses differences
## for the low count genes for which the data provide little information about differential expression.
lapply(names(ddsTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_rlog_comparison_two_samples.png"))
    print(file.name)
    png(filename = file.name, width = 480*2, height = 480*2, res = 100)
    par( mfrow = c( 1, 3 ) )
    ## lims <- c(-2, 20)
    lims <- c()
    ## plot(log2(counts(ddsTC[[seg.time]], normalized=TRUE)[,c(1,10)] + 1),
    plot(log2(counts(ddsTC[[seg.time]], normalized=TRUE)[, c(1,10)] + 1),
         pch=16, cex=0.3, main = "log2(x+1)", xlim = lims, ylim=lims)
    ## plot(assay(rldTC[[seg.time]])[,c(1,10)],
    plot(assay(rldTC[[seg.time]])[,c(1,10)],
         pch=16, cex=0.3, main = "rlog", xlim = lims, ylim = lims)
    plot(assay(vsdTC[[seg.time]])[,c(1,10)],
         pch=16, cex=0.3, main = "VST", xlim = lims, ylim = lims)
    dev.off()
    })

## Measuring similarity between samples
## sampleDists <- dist(t(assay(rld)))

## Normal distance heatmap (rlog)
lapply(names(rldTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_rlog_standard_heatmap.png"))
    print(file.name)    
    rld <- rldTC[[seg.time]]
    sampleDists <- dist(t(assay(rld)))
    sampleDistMatrix <- as.matrix(sampleDists)
    rownames(sampleDistMatrix) <- paste0(rld$group,".",rld$timepoint,".",rld$replicate)
    colnames(sampleDistMatrix) <- NULL
    colors <- colorRampPalette(rev(brewer.pal(9, "Blues")) )(255)
    ## png(filename = paste0(seg.time, "_rlog_standard_heatmap.png"), width = 480*2, height = 480*2, res = 100)
    pheatmap(sampleDistMatrix,
             clustering_distance_rows=sampleDists,
             clustering_distance_cols=sampleDists,
             col=colors,
             fontsize_row = 7,
             filename = file.name)
    ## dev.off()
})

## Normal distance heatmap (vst)
lapply(names(vsdTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_vsd_standard_heatmap.png"))
    print(file.name)    
    rld <- vsdTC[[seg.time]]
    sampleDists <- dist(t(assay(rld)))
    sampleDistMatrix <- as.matrix(sampleDists)
    rownames(sampleDistMatrix) <- paste0(rld$group,".",rld$timepoint,".",rld$replicate)
    colnames(sampleDistMatrix) <- NULL
    colors <- colorRampPalette(rev(brewer.pal(9, "Blues")) )(255)
    ## png(filename = paste0(seg.time, "_vsd_standard_heatmap.png"), width = 480*2, height = 480*2, res = 100)
    pheatmap(sampleDistMatrix,
             clustering_distance_rows=sampleDists,
             clustering_distance_cols=sampleDists,
             col=colors,
             fontsize_row = 7,
             filename = file.name)
    ## dev.off()
    })


## Poisson Distance heatmap (rlog)
lapply(names(ddsTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_rlog_poisson_heatmap.png"))
    print(file.name)    
    rld <- rldTC[[seg.time]]
    poisd <- PoissonDistance(t(counts(ddsTC[[seg.time]])))
    samplePoisDistMatrix <- as.matrix( poisd$dd )
    rownames(samplePoisDistMatrix) <- paste0(rld$group,".",rld$timepoint,".",rld$replicate)    
    colnames(samplePoisDistMatrix) <- NULL
    colors <- colorRampPalette(rev(brewer.pal(9, "Blues")) )(255)    
    ## png(filename = paste0(seg.time, "_", "rlog_poisson_heatmap.png"), width = 480*2, height = 480*2, res = 100)
    pheatmap(samplePoisDistMatrix,
             clustering_distance_rows=poisd$dd,
             clustering_distance_cols=poisd$dd,
             col=colors,
             fontsize_row = 7,
             filename = file.name
             )
    ## dev.off()
})

## Poisson Distance heatmap (vsd)
lapply(names(ddsTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_vsd_poisson_heatmap.png"))
    print(file.name)        
    rld <- vsdTC[[seg.time]]
    poisd <- PoissonDistance(t(counts(ddsTC[[seg.time]])))
    samplePoisDistMatrix <- as.matrix( poisd$dd )
    rownames(samplePoisDistMatrix) <- paste0(rld$group,".",rld$timepoint,".",rld$replicate)    
    colnames(samplePoisDistMatrix) <- NULL
    colors <- colorRampPalette(rev(brewer.pal(9, "Blues")) )(255)    
    ## png(filename = paste0(seg.time, "_", "vsd_poisson_heatmap.png"), width = 480*2, height = 480*2, res = 100)
    pheatmap(samplePoisDistMatrix,
             clustering_distance_rows=poisd$dd,
             clustering_distance_cols=poisd$dd,
             col=colors,
             fontsize_row = 7,
             filename = file.name
             )
    ## dev.off()
})

## PCA plot of the samples (rlog)
lapply(names(rldTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_rlog_timecourse_PCA.png"))
    print(file.name)        
    rld <- rldTC[[seg.time]]
    ## (data <- plotPCA(rld, intgroup = c("group", "timepoint", "replicate"), returnData = TRUE))
        (data <- plotPCA(rld, intgroup = c("timepoint", "treatment"), returnData = TRUE))   
    percentVar <- round(100 * attr(data, "percentVar"))
    ## data$timepoint <- as.factor(data$timepoint)
    ## p <- ggplot(data, aes(PC1, PC2, color=treatment, shape=timepoint)) + geom_point(size=3) +
    p <- ggplot(data, aes(PC1, PC2)) + 
        geom_point(aes(color=treatment, shape = timepoint), size = 3) +
        xlab(paste0("PC1: ",percentVar[1],"% variance")) +
        ylab(paste0("PC2: ",percentVar[2],"% variance")) +
        coord_fixed()
    ## p <- plotPCA(rld, intgroup = c("group", "timepoint"))
    ggsave(file.name, plot = p)
})

## PCA plot of the samples (vsd)
lapply(names(vsdTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_vsd_timecourse_PCA.png"))
    print(file.name)    
    rld <- vsdTC[[seg.time]]
    (data <- plotPCA(rld, intgroup = c("timepoint", "treatment"), returnData = TRUE))   
    percentVar <- round(100 * attr(data, "percentVar"))
    ## data$timepoint <- as.factor(data$timepoint)
    ## p <- ggplot(data, aes(PC1, PC2, color=group, shape=timepoint)) + geom_point(size=3) +
    p <- ggplot(data, aes(PC1, PC2)) + 
        geom_point(aes(color = treatment, shape = timepoint), size = 3) +
        xlab(paste0("PC1: ",percentVar[1],"% variance")) +
        ylab(paste0("PC2: ",percentVar[2],"% variance")) +
        coord_fixed()
    ggsave(file.name, plot = p)
})


## Making fviz_pca (rlog)
lapply(names(rldTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_rlog_timecourse_PCA_treatment_fviz_pca_ind.png"))
    print(file.name)        
    rld <- rldTC[[seg.time]]
    rv <- genefilter::rowVars(assay(rld))
    select <- order(rv, decreasing = TRUE)[seq_len(min(500, length(rv)))]
    pca <- prcomp(t(assay(rld)[select, ]))
    p <- fviz_pca_ind(pca, label = "all", invisible="ind", alpha.var = "contrib",
                      habillage = rld$treatment, addEllipses = T, jitter = list(what = "b", width = 10, height = 15))
    ggsave(file.name, plot = p)
})

## Making fviz_pca (vsd)
lapply(names(vsdTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_vsd_timecourse_PCA_treatment_fviz_pca_ind.png"))
    print(file.name)        
    rld <- vsdTC[[seg.time]]
    rv <- genefilter::rowVars(assay(rld))
    select <- order(rv, decreasing = TRUE)[seq_len(min(500, length(rv)))]
    pca <- prcomp(t(assay(rld)[select, ]))
    p <- fviz_pca_ind(pca, label = "all", invisible="ind", alpha.var = "contrib",
                      habillage = rld$treatment, addEllipses = T, jitter = list(what = "b", width = 10, height = 15))
    ggsave(file.name, plot = p)
})


## MDS plot of the samples (rlog)
lapply(names(rldTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_rlog_timecourse_MDS.png"))
    print(file.name)            
    rld <- rldTC[[seg.time]]
    sampleDists <- dist(t(assay(rld)))
    sampleDistMatrix <- as.matrix(sampleDists)
    mdsData <- data.frame(cmdscale(sampleDistMatrix))
    mds <- cbind(mdsData, as.data.frame(colData(rld)))
    mds$timepoint <- as.factor(mds$timepoint)
    p <- ggplot(mds, aes(X1,X2,color=treatment,shape=timepoint)) + geom_point(size=3) +
        coord_fixed()
    ggsave(file.name, plot = p)
})

## MDS plot of the samples (vsd)
lapply(names(vsdTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_vsd_timecourse_MDS.png"))
    print(file.name)            
    rld <- vsdTC[[seg.time]]
    sampleDists <- dist(t(assay(rld)))
    sampleDistMatrix <- as.matrix(sampleDists)
    mdsData <- data.frame(cmdscale(sampleDistMatrix))
    mds <- cbind(mdsData, as.data.frame(colData(rld)))
    mds$timepoint <- as.factor(mds$timepoint)
    p <- ggplot(mds, aes(X1,X2,color=treatment,shape=timepoint)) + geom_point(size=3) +
        coord_fixed()
    ggsave(file.name, plot = p)
})

  
## Poisson Distance MDS plot (rlog)
lapply(names(ddsTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_rlog_timecourse_Poisson_MDS.png"))
    print(file.name)            
    rld <- rldTC[[seg.time]]
    ddsTC <- ddsTC[[seg.time]]
    poisd <- PoissonDistance(t(counts(ddsTC)))
    samplePoisDistMatrix <- as.matrix( poisd$dd )
    mdsPoisData <- data.frame(cmdscale(samplePoisDistMatrix))
    mdsPois <- cbind(mdsPoisData, as.data.frame(colData(ddsTC)))
    mdsPois$timepoint <- as.factor(mdsPois$timepoint)
    p <- ggplot(mdsPois, aes(X1,X2,color=treatment,shape=timepoint)) + geom_point(size=3) +
        coord_fixed()
    ggsave(file.name, plot = p)
})

## Poisson Distance MDS plot (vsd)
lapply(names(ddsTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    file.name <- file.path(dired, paste0(dired, "_vsd_timecourse_Poisson_MDS.png"))
    print(file.name)            
    rld <- vsdTC[[seg.time]]
    ddsTC <- ddsTC[[seg.time]]
    poisd <- PoissonDistance(t(counts(ddsTC)))
    samplePoisDistMatrix <- as.matrix( poisd$dd )
    mdsPoisData <- data.frame(cmdscale(samplePoisDistMatrix))
    mdsPois <- cbind(mdsPoisData, as.data.frame(colData(ddsTC)))
    mdsPois$timepoint <- as.factor(mdsPois$timepoint)
    p <- ggplot(mdsPois, aes(X1,X2,color=treatment,shape=timepoint)) + geom_point(size=3) +
        coord_fixed()
    ggsave(file.name, plot = p)
})


#################### TIME COURSE DIFFERENTIAL EXPRESSION ANALYSIS ####################
threads <- 40
register(MulticoreParam(workers = threads))

## early.ddsTC <- DESeqDataSetFromTximport(txi = early.txi, colData = early.sampleTable, design = ~ 0 + genotype*treatment*timepoint)
## middle.ddsTC <- DESeqDataSetFromTximport(txi = middle.txi, colData = middle.sampleTable, design = ~ 0 + genotype*treatment*timepoint)
## late.ddsTC <- DESeqDataSetFromTximport(txi = late.txi, colData = late.sampleTable, design = ~ 0 + genotype*treatment*timepoint)
## ddsTC <- list(early = early.ddsTC, middle = middle.ddsTC, late = late.ddsTC)

ddsTC.run <- lapply(names(ddsTC), function(seg.time) {
    ## DESeq(ddsTC[[seg.time]], test = "LRT", reduced = ~ 0 + genotype * treatment + timepoint, parallel = TRUE)
    DESeq(ddsTC[[seg.time]], test = "LRT", reduced = ~ 0 + treatment + timepoint , parallel = TRUE)
})
names(ddsTC.run) <- names(ddsTC)

resTC <- lapply(names(ddsTC.run), function(seg.time) {
    dds <- ddsTC.run[[seg.time]]
    results <- lapply(resultsNames(dds), function(result) {
        res <- results(dds, alpha = 0.05, parallel = TRUE, name = result)
        return(res)
    })
    names(results) <- resultsNames(dds)
    return(results)
})
names(resTC) <- names(ddsTC)

## plotCounts for the most significant gene
lapply(names(resTC), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    print(dired)
    ## dired <- file.path(paste0("Time_", seg.time), "plotCounts")
    ## dir.create(dired)
    res <- resTC[[seg.time]]
    dds <- ddsTC.run[[seg.time]]
    resu <- names(res)[[1]]
    res <- res[[resu]]
    topGene <- rownames(res)[which.min(res$padj)]
    geneCounts <- plotCounts(dds, gene=topGene, intgroup = c("timepoint", "treatment"), returnData = TRUE)
    p <- ggplot(geneCounts, aes(x = treatment, y = count, color = timepoint)) +
        scale_y_log10() +
        geom_point(position=position_jitter(width=.1, height=0), size=3) +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
    ## ggsave(filename = file.path(dired, paste0(seg.time,"_",resu,"_",topGene,"_plotCounts.png")), plot = p)
    ggsave(filename = file.path(dired, paste0(dired,"_",topGene,"_plotCounts.png")), plot = p)
    p <- ggplot(geneCounts, aes(x = treatment, y = count, fill = timepoint)) +
        scale_y_log10() +
        geom_dotplot(binaxis = "y", stackdir = "center") +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
    ggsave(filename = file.path(dired, paste0(dired,"_", topGene, "_outline_plotCounts.png")), plot = p)
    p <- ggplot(geneCounts, aes(x = treatment, y = count, color = timepoint, group = timepoint)) +
        scale_y_log10() + geom_point(size = 3) + geom_line() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
    ggsave(filename = file.path(dired, paste0(dired,"_", topGene, "_structural_plotCounts.png")), plot = p)
})


## MA plots of the results
lapply(names(resTC), function(seg.time) {
    dired1 <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired1)
    print(dired)
    res <- resTC[[seg.time]]
    dired2 <- file.path(dired1, "MAplots")
    dir.create(dired2)
    print(dired2)
    lapply(names(res), function(rName) {
        res <- res[[rName]]
        png(filename = file.path(dired2, paste0(dired1, "_", rName,"_MAplot.png")), width = 480*2, height = 480*2, res = 100)
        plotMA(res, ylim = c(-5, 5))
        dev.off()
        png(filename = file.path(dired2, paste0(dired1, "_", rName,"_most.sig_MAplot.png")), width = 480*2, height = 480*2, res = 100)
        plotMA(res, ylim = c(-5, 5))
        topGene <- rownames(res)[which.min(res$padj)]
        with(res[topGene, ], {
            points(baseMean, log2FoldChange, col="dodgerblue", cex=2, lwd=2)
            text(baseMean, log2FoldChange, topGene, pos=2, col="dodgerblue")
        })
        dev.off()
    })
})

## Histogram of the results (removing too low counts)
lapply(names(resTC), function(seg.time) {
    dired1 <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired1)
    print(dired1)
    res <- resTC[[seg.time]]
    dired2 <- file.path(dired1, "Histograms")
    dir.create(dired2)
    print(dired2)    
    lapply(names(res), function(rName) {
        res <- res[[rName]]
        res <- res[!is.na(res$pvalue) & res$pvalue <1, ]
        png(filename = file.path(dired2, paste0(dired1, "_", rName,"_Histogram.png")), width = 480*2, height = 480*2, res = 100)
        hist(res$pvalue[res$baseMean > 1], breaks=0:20/20, col = "grey50", border = "white")
        dev.off()
    })
})

## plotCounts for timeCourse
lapply(names(ddsTC.run), function(seg.time) {
    dired <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired)
    print(dired)    
    dds <- ddsTC.run[[seg.time]]
    res <- resTC[[seg.time]]
    gene <- rownames(res[[1]])[which.min(res[[1]]$padj)]
    data <- plotCounts(dds, which.min(res[[1]]$padj),
                       intgroup = c("timepoint", "treatment"), returnData = TRUE)
    p <- ggplot(data, aes(x = timepoint, y = log10(count), color = treatment, group = treatment)) +
        geom_point() + stat_smooth(se = FALSE, method = "loess") +
        theme(strip.text.x = element_text(size = 7.5)) +
        labs(y = "DESeq2 normalized counts (log10)", x = "Days after planting",
             title = paste0("Condition-specific changes over time for: ", gene)) +
        facet_grid(~ treatment)
    ggsave(filename = file.path(dired, paste0(dired, "_", gene, "_timecourse_plotCounts.png")), plot = p, width = 10, height = 10)
})

## plot of log2 fold changes in heatmap
lapply(names(resTC), function(seg.time) {
    dired1 <- gsub("%", "", seg.time, fixed = T)
    dir.create(dired1)
    print(dired1)        
    res <- resTC[[seg.time]]
    dds <- ddsTC.run[[seg.time]]
    dired2 <- file.path(dired1, "clusterHeatmaps")
    dir.create(dired2)
    lapply(names(res), function(rName) {
        ## if(grepl("timepoint", rName) != TRUE) {
        ##     return(NULL)
        ## }
        res <- results(dds, name = rName, test = "Wald")
        betas <- coef(dds)
        topGenes <- head(order(res$padj), 20)
        mat <- betas[topGenes, -c(1,2)]
        thr <- 3
        mat[mat < -thr] <- -thr
        mat[mat > thr] <- thr
        ## colnames(mat) <- gsub("group", "", colnames(mat))
        ## mat <- mat[, c(colnames(mat)[1:3],unlist(lapply(lapply(unique(sort(gsub("timepoint\\d+$", "",colnames(mat)[4:ncol(mat)])))[c(2,1,3,4,5,7,6,8)], grep, colnames(mat), fixed = T), function(x) { colnames(mat)[x] })))]
        p <- pheatmap(mat, breaks=seq(from=-thr, to=thr, length=101), cluster_col = FALSE,
                      filename = file.path(dired2, paste0(dired1,"_",rName,"_clusterHeatmap.png")))
    })
})

## Finding all significant genes, then joining with table and getting GO terms.
go.terms <- read.csv(file = file.path(annotation.path, go.file), sep = "\t", stringsAsFactors = F)
bd.defline <- read.csv(file = file.path(annotation.path, def.file), sep = "\t", header = F, stringsAsFactors = F)
colnames(bd.defline) <- c("locusName", "brachy.defline")
bd.defline[, "locusName"] <- gsub("\\.\\d", "", bd.defline[, "locusName"])
go.terms.all <- go.terms[, c(2,10,13,16)]
go.terms.all$GO <- NULL
go.terms <- go.terms[, c(2, 10)]

genes <- lapply(names(resTC), function(seg.time) {
    res <- resTC[[seg.time]][[1]]
    genes <- data.frame(locusName = rownames(res[res$padj < 0.05 & !is.na(res$padj), ]))
    GO <- merge(genes, go.terms, by = "locusName")
    GO$Panther <- NULL
    print(seg.time)
    GO.many <- apply(GO, 1, function(x) {
        terms <- unlist(strsplit(as.character(x[2]), ","))
        if(length(terms) > 1) {
            new.rows <- lapply(terms, function(y) {
                x[2] <- y
                return(unname(x))
            })
        }
    })
    if(is.null(GO.many)) {
        print("No one to many GO terms...")
    } else {
        GO.many <- do.call(rbind, unlist(GO.many, rec = F))
    }
    GO.one <- apply(GO, 1, function(x) {
        terms <- unlist(strsplit(as.character(x[2]), ","))
        if(length(terms) <=1) {
            if(x[2] == "") { x[2] <- NA }
            return(unname(x))
        }
    })
    if(is.null(GO.one) & is.null(GO.many)) {
        print("No GO terms at all..")
        return(GO)
    } else if(is.null(GO.one)) {
        print("No one term GO obut we do have many GO...")
        GO <- data.frame(GO.many, stringsAsFactors = FALSE)
    } else if(is.null(GO.many)) {
        GO <- GO
    } else {
        GO.one <- do.call(rbind, GO.one)
        GO <- data.frame(rbind(GO.one, GO.many), stringsAsFactors = FALSE)
    }
    colnames(GO) <- c("locusName", "GOID")
    terms <- GO[!is.na(GO$GOID), ]$GOID
    if(terms != "") {
        tmp <- select(GO.db, keys = terms, columns = c("TERM", "ONTOLOGY"), keytype = "GOID")
        colnames(tmp) <- c("GOID", "Term", "Ontology")
        final <- merge(GO, tmp, by = "GOID", all.x = T)
        final <- final[, c(2,1,4,3)]
        return(final)        
    } else {
        return(GO)
    }
})
names(genes) <- names(resTC)

genes.DT <- lapply(genes, function(seg.time) {
    unique(data.table(seg.time))
})

## Slight removal of Bd3.45% will be given later...maybe
genes.DT[["Bd3.45%"]] <- NULL

go.terms.all <- data.table(go.terms.all)
bd.defline <- data.table(bd.defline)

genes.merge <- lapply(names(genes.DT), function(seg.time) {
    res <- genes.DT[[seg.time]]
    setkey(res, locusName)
    setkey(go.terms.all, locusName)
    setkey(bd.defline, locusName)
    ## res <- merge(res, go.terms.all, all.x = TRUE)
    ## res <- merge(res, bd.defline, all.x = TRUE)
    res1 <- merge(res, go.terms.all, by = "locusName")
    res2 <- merge(res1, bd.defline, by = "locusName")
    return(res2)
})
names(genes.merge) <- names(genes.DT)

test <- genes.merge

final.table <- rbindlist(test, use.names = TRUE, idcol = "test")
test.final <- final.table
test.final[, genotype:=gsub("\\..*", "", final.table$test)]
test.final[, genotype:=ifelse(test.final[, genotype] == "Bd21", "Bd21-0", ifelse(test.final[, genotype] == "Bd3", "Bd3-1", "Bd1-1"))]
test.final[, treatment:=gsub("^Bd\\d\\d?\\.", "", final.table$test)]
test.final <- unique(test.final)

fwrite(test.final, "final_table_sig_genes_GO_Terms.csv") 

lapply(names(genes), function(seg.time) {
    dired <- paste0("Time_", seg.time)
    write.csv(genes[[seg.time]], file = file.path(dired, paste0(dired, "_GO_Terms.csv")), row.names = F)
    })

final.tables <- lapply(names(ddsTC.run), function(seg.time) {
    ddsTC <- ddsTC.run[[seg.time]]
    dired <- paste0("Time_", seg.time)
    print(dired)
    dir.create(dired)
    results <- lapply(resultsNames(ddsTC), function(result) {
        resTC <- results(ddsTC, alpha = 0.05, parallel = TRUE, name = result)
        resTC.Ordered <- resTC[order(resTC$padj), ]
        sink(file.path(dired ,paste0(dired, "_", "summary_", result,".txt")))
        print(summary(resTC.Ordered))
        sink()
        resTCOrderedDF <- as.data.frame(resTC.Ordered)
        resTCOrderedDF$symbol <- bdist.merge[match(rownames(resTC.Ordered), bdist.merge$ens_gene),]$symbol
        resTCOrderedDF$genes <- rownames(resTCOrderedDF)
        resTCOrderedDF <- resTCOrderedDF[, c("symbol", setdiff(names(resTCOrderedDF), "symbol"))]
        resTCOrderedDF <- resTCOrderedDF[, c("genes", setdiff(names(resTCOrderedDF), "genes"))]
        write.csv(resTCOrderedDF, file = file.path(dired, paste0(dired, "_", result, "_comparisons_results.csv")), row.names = FALSE)
        return(resTCOrderedDF)
    })
    names(results) <- resultsNames(ddsTC)
    return(results)
})
names(final.tables) <- c("early", "middle", "late")

## Melting for data manipulation
final <- lapply(names(final.tables), function(final) {
    tables <- final.tables[[final]]
    res.final <- lapply(names(tables), function(table) {
        res <- tables[[table]]
        ## res[, "name"] <- paste0(final, "_", table)
        res[, "name"] <- table     
        res <- melt(res, id = c("genes", "symbol", "name"))
    })
    melted.df <- do.call(rbind, res.final)
    return(melted.df)
})
names(final) <- c("early", "middle", "late")

b <- lapply(c("early", "middle", "late"), function(seg.time) {
    samp.Table <- eval(parse(text = paste0(seg.time, ".sampleTable")))
    g.ref <- gsub("-", ".", as.character(sort(unique(samp.Table[, "genotype"])))[[1]])
    g.ref <- paste0(g.ref, ".")
    treat.ref <- paste0(".treatment", substr(as.character(sort(unique(samp.Table[, "treatment"])))[[1]],1,2), ".")
    time.ref <- paste0(".timepoint", as.character(sort(unique(samp.Table[, "timepoint"]))[[1]]))
    tables <- final[[seg.time]]
    test <- dcast(tables, genes + symbol + name ~ variable, value.var = "value")
    test <- test[test$padj < 0.05 & !is.na(test$padj), ]
    a <- sort(unique(test$name))
    a[grep("genotypeBd\\d\\d?\\.\\d$", a)] <- paste0(grep("genotypeBd\\d\\d?\\.\\d$", a, val =T), treat.ref, time.ref)
    a[grep("^treatment.*timepoint\\d\\d$", a)] <- paste0("genotype", g.ref,grep("^treatment.*timepoint\\d\\d$", a, val = T))
    a[grep("^timepoint\\d\\d$", a)] <- paste0("genotype", g.ref, treat.ref, grep("^timepoint\\d\\d$", a, val = T))
    a[grep("^treatment\\d\\d?\\.\\d?\\d?\\.?$", a)] <- paste0("genotype", g.ref, grep("^treatment\\d\\d?\\.\\d?\\d?\\.?$", a, val = T), time.ref)
    rep.in.between <- sapply(strsplit(gsub("(\\d)\\.t", "\\1.,t",grep("genotypeBd\\d\\d?\\.\\d\\.timepoint\\d+$", a, val = T)), ","), paste, collapse = paste0(treat.ref, "."))
    a[grep("genotypeBd\\d\\d?\\.\\d\\.timepoint\\d+$", a)] <- rep.in.between
    a[grep("genotypeBd\\d\\.\\d\\.treatment\\d\\d\\.\\d?\\d?\\.?$", a)] <- paste0(grep("genotypeBd\\d\\.\\d\\.treatment\\d\\d\\.\\d?\\d?\\.?$", a, val = T), time.ref)
    a[grep("^treatment\\w+$", a)] <- paste0("genotype",g.ref, grep("^treatment\\w+$", a, val = T), time.ref)
    a[grep("genotypeBd\\d\\.\\d\\.treatment\\w+$", a)] <- paste0(grep("genotypeBd\\d\\.\\d\\.treatment\\w+$", a, val = T), time.ref)
    a <- gsub("\\.\\.", "\\.", a)
    a <- gsub("(\\d)\\.treat", "\\1,treat", a)
    a <- gsub("(\\d?\\w+?)\\.timepoint", "\\1,timepoint", a)
    a.splt <- lapply(strsplit(a, ','), function(z) {
        res <- sapply(z ,function(x) {
            ifelse(grepl("genotype", x), gsub("genotype", "", x),
            ifelse(grepl("treatment", x), gsub("treatment", "", x),
            ifelse(grepl("timepoint", x), gsub("timepoint", "", x), NA)))
        })
        names(res) <- c("genotype", "treatment", "timepoint")
        return(res)
    })
    a.splt <- data.frame(do.call(rbind, a.splt))
    test <- cbind(test, a.splt[match(test$name, sort(unique(test$name))),])
    test[, "name"] <- NULL
    test[, c("pvalue", "lfcSE", "stat")] <- NULL
    p <- ggplot(test, aes(x = timepoint, y = log2FoldChange, color = treatment)) +
        geom_boxplot() +
        facet_wrap(~ genotype + treatment)
    ggsave(paste0(seg.time, "_compare_genes.png"), p)
    })

## Only significantly different genes for Sarit
res.p <- lapply(names(resTC), function(seg.time) {
    dired <- paste0("Time_", seg.time)    
    dir.create(dired)
    res <- resTC[[seg.time]]
    res.p <- res[res$padj < 0.05 & !is.na(res$padj), ]
    res.p <- as.data.frame(res.p)
    res.p$symbol <- bdist.gene.symbols[match(rownames(res.p), bdist.gene.symbols$ens_gene), ]$symbol
    res.p$genes <- rownames(res.p)
    res.p <- res.p[, c("symbol", setdiff(names(res.p), "symbol"))]
    res.p <- res.p[, c("genes", setdiff(names(res.p), "genes"))]
    write.csv(res.p, file = file.path(dired, paste0(dired,"_significantly_different_genes.csv")), row.names = FALSE)
    return(res.p)
    })


################### END OF CURRENT ENCODE ##############################

## HTML Report
desReport <- HTMLReport(shortName="Mockler_Lab_RNAseq_analysis_with_DESeq2", title="Mockler Lab RNA-seq analysis",
                        reportDirectory="./reports")
publish(resTCOrderedDF, desReport)
url <- finish(desReport)
browseURL(url)

## regionReport
dir.create("regionReport")
report <- DESeq2Report(ddsTC.run[["early"]], project = "ENCODE_RNAseq_analysis_with_DESeq2",
                       intgroup = c("treatment", "timepoint"), res = resTC, outdir = "regionReport",
                       output = 'index', theme = theme_bw())

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
