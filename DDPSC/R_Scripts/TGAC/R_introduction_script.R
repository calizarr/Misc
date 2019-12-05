
# Basic mathematical operations

# Define two integer variables
x <- 7
y <- 8

# Sum them
x + y

# Multiply them
x*y

# Square the sum
(x+y)^2

# Define two arrays (height and weight)
inches <- c(70,72,68,71,65)

pounds <- c(180,195,135,165,125)

# Make a scatterplot
plot(inches,pounds)

# Summary statistics
length(inches)

sum(inches)/length(inches)

mean(inches)

sd(inches)

max(inches)

min(inches)

summary(inches)

# More plotting of simulated data (100 measures)
inches.sim <- rnorm(100, mean=mean(inches), sd=sd(inches))
inches.sim

boxplot(inches.sim, main="Boxplot Example", ylab="inches")

dotchart(inches.sim)

hist(inches.sim)

# Simulate gene expression data for 1000 fake genes, two sample groups (n=5)

ControlExp <- runif(1000, min=1, max=12)

AffectedGenes <- sample(1:1000,100)

EffectSize <- rnorm(100, sd=3)

sum(abs(EffectSize) > 1)

hist(ControlExp, xlab="Gene Expression (log2)")

array <- matrix(nrow=1000, ncol=10)

# Label the samples
colnames(array) <- c("C1","C2","C3","C4","C5","T1","T2","T3","T4","T5")
rownames(array) <- 1:1000

# Set each array value to values from ControlExp plus noise
for(i in 1:10){
   array[,i] <- ControlExp + rnorm(1000, sd=.5)
}

# Add treatment effect to just treated samples
for(i in 6:10){
   array[AffectedGenes,i] <- array[AffectedGenes,i] + EffectSize
}

# Scatterplot
pairs(array, pch='.',xlim=c(0,12),ylim=c(0,12))

# HeatMap
library(gplots)

heatmap.2(array[AffectedGenes,],dendrogram="both",
trace="none",scale="row",main="Affected Genes")

pdf("heatmap.pdf")
heatmap.2(array[AffectedGenes,],dendrogram="both",
trace="none",scale="row",main="Affected Genes")
dev.off()

