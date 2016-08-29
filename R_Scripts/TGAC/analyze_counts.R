
library(edgeR)

# Read in count data as a comma-separated text file
rawdata <- read.csv(file = "counts.csv")

# Report column labels to make sure they are correct
names(rawdata)

# Report first row of data to make sure it looks okay
rawdata[1,]

# Construct a new matrix so that geneIDs are used as row labels
data <- rawdata[, 2:9]
rownames(data) <- rawdata[,1]

# Report first row of data to make sure it looks okay
data[1,]

# Filter out lowly expressed genes
#  a. check distribution of counts for unfiltered genes
summary(rowSums(data))
#  b. filter genes
filtered <- data[which(rowSums(data) > 10), ]
#  c. check distribution of counts for filtered genes
summary(rowSums(filtered))

# Boxplots - Added 1 to all filtered counts to avoid log2(0)
png("boxplots.png")
boxplot(log2(filtered+1),ylab="log2(Counts)",main="Filtered RNA-Seq Counts")
dev.off()

# Scatterplot
png("scatterplot.png")
pairs(log2(filtered),pch='.')
dev.off()

# Created DGEList using filtered counts
DGE <- DGEList(counts = filtered, genes = row.names(filtered))

# Normalize data by read depth per sample
DGE <- calcNormFactors(DGE)

# Obtain summary of DGEList
DGE

# Take paired design of experiment into account by having a cell line (donor) factor
# along with treatment factor

donor <- factor(c(1, 2, 3, 4, 1, 2, 3, 4))
treatment <- factor(c("CTRL", "CTRL", "CTRL", "CTRL", "DEX", "DEX", "DEX", "DEX"))

# Visualize how factors can be combined into a "design matrix"
data.frame(sample = colnames(DGE), donor, treatment)

# Make design matrix
design <- model.matrix(~ donor + treatment)
rownames(design) <- colnames(DGE)

# Estimate dispersion
DGE <- estimateGLMCommonDisp(DGE, design, verbose = TRUE)

DGE <- estimateGLMTrendedDisp(DGE, design)

DGE <- estimateGLMTagwiseDisp(DGE, design)

# Obtain summary of DGEList
DGE

# Plot biological coefficient of variation
png("biological_coefficient_of_variation.png")
plotBCV(DGE)
dev.off()

# Fit model using design matrix
fit <- glmFit(DGE, design)

# Identify differentially expressed genes using likelihood ratio test
lrt <- glmLRT(fit)

# Report topTags
topTags(lrt)

# Report how many are up- or down-regulated
DE <- decideTestsDGE(lrt, adjust.method = "fdr")
summary(DE)

# Save results for all genes regardless of significance
results <- as.data.frame(topTags(lrt, n = length(rownames(DGE$counts))))

# Write results to a tab-delimited text file
write.table(results,"CTRL_DEX_results.txt",sep="\t",row.names=FALSE,quote=FALSE)

# Make MA plot
pdf("MAplot.pdf")
detags <- rownames(DGE)[as.logical(DE)]
plotSmear(lrt, de.tags = detags)
abline(h = c(-1, 1), col="blue")
dev.off()














