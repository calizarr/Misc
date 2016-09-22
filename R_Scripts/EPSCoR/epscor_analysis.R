source('sit.gz')
## Removing the portions of the code that aren't needed and keeping the plot.table functions
## rm(list=setdiff(ls(), c(ls()[grep("plot.table", ls())], "iif"))
library(ggplot2)
capitalize <- function(x) paste0(toupper(substr(x, 1, 1)), tolower(substring(x, 2)))

greenhouse.data <- read.csv("Cesar_GH2Master_20160330.csv", na.strings = c("", " ", "#DIV/0!", "NA"))
## Removing all of the empty columns
greenhouse.data <- greenhouse.data[, colSums(is.na(greenhouse.data)) < nrow(greenhouse.data)]
## Removing all of the notes columns
greenhouse.data <- greenhouse.data[, -grep("notes", colnames(greenhouse.data))]
## Removing rows that are all NA
greenhouse.data <- greenhouse.data[rowSums(is.na(greenhouse.data)) != length(colnames(greenhouse.data)), ]
## Making sure that treatment is a factor vector.
greenhouse.data[, "treatment"] <- as.factor(greenhouse.data[, "treatment"])
greenhouse.data[, "replication"] <- as.factor(greenhouse.data[, "replication"])
greenhouse.data[, "chlorophyll_content1"] <- as.numeric(greenhouse.data[, "chlorophyll_content1"])
## Removing all date columns from data frame
greenhouse.data[, grep("date", names(greenhouse.data))] <- list(NULL)

## Removing any column that contains at least one N.A.
greenhouse.data.purged <- greenhouse.data[, colSums(is.na(greenhouse.data)) == 0]

## Removing any column that contains at least 20% NAs or
greenhouse.data.semi <- greenhouse.data[, colSums(is.na(greenhouse.data)) < 0.20 * length(greenhouse.data[, 1])]

## Proper plots with ggplot for the data.
analyze.trait <- function(dfr, trait, col1, col2, treat1, treat2) {
  ## Creating image directory
  dir.create("Images")
  dfr[, "dividers"] <- ifelse(dfr[, col2] == treat2, "Yes", "No")
  ## Looping through the genotypes
  ## Complete plot of all genotype X treatment interactions
  p.xlab1 <- paste(capitalize(col1), capitalize(col2), sep = " X ")
  p <- ggplot(dfr, aes_string(x = paste("interaction(", col1,", ", col2,")", sep = ""), y = trait, fill = col2), environment = environment()) + geom_boxplot() +
    theme(axis.text.x = element_text(angle=90, vjust=0.5, size=10),
      panel.grid.major = element_blank()) +
      ## panel.grid.minor = element_blank()) +
    scale_x_discrete(limits = sort(as.character(unique(interaction(dfr[, col1], dfr[, col2]))))) +
    xlab(p.xlab1) +
    guides(fill = guide_legend(title = capitalize(col2))) +
    ggtitle(paste(capitalize(trait), " VS ", p.xlab1)) +
    geom_vline(xintercept = seq(from = 2.5, to = length(unique(dfr[, col1])) * length(unique(dfr[, col2])), by = 2), linetype = 3)
  print(p)
  ggsave(p, filename = file.path("Images", paste0(paste(trait, "VS", capitalize(col1),"X", capitalize(col2), sep = "_"), ".png")), width = 10)

  ## Design of Experiment scatter plot instead of boxplot
  p <- ggplot(dfr, aes_string(x = paste("interaction(", col1,", ", col2,")", sep = ""), y = trait, color = col2), environment = environment()) + geom_point() + geom_line() +
    theme(axis.text.x = element_text(angle=90, vjust=0.5, size=10)) +
    scale_x_discrete(limits = sort(as.character(unique(interaction(dfr[, col1], dfr[, col2]))))) +
    xlab(p.xlab1) +
    guides(fill = guide_legend(title = capitalize(col2))) +
    ggtitle(paste(capitalize(trait), " VS ", p.xlab1))
  print(p)
  ggsave(p, filename = file.path("Images", paste0(paste(trait, "VS", capitalize(col1),"X", capitalize(col2), "Scatter", sep = "_"), ".png")), width = 10)

  ## Plot of genotype X treatment interactions with treatments combined.
  p <- ggplot(dfr, aes_string(x = col1, y = trait, fill = col1), environment = environment()) + geom_boxplot() +
    theme(axis.text.x = element_text(angle=90, vjust=0.5, size=10)) +
    scale_x_discrete(limits = sort(as.character(unique(dfr[, col1])))) +
    xlab(paste(capitalize(col1))) +
    guides(fill = guide_legend(title = capitalize(col1))) +
    ggtitle(paste(capitalize(trait), " VS ", capitalize(col1)))
  print(p)
  ggsave(p, filename = file.path("Images", paste0(paste(trait, "VS", capitalize(col1), sep = "_"), ".png")), width = 10)

  ## Plot of trait for each treatment across all genotypes
  p <- ggplot(dfr, aes_string(x = col2, y = trait, fill = col2), environment = environment()) + geom_boxplot() +
    ## theme(axis.text.x = element_text(angle=90, vjust=0.5, size=10)) +
    scale_x_discrete(limits = sort(as.character(unique(dfr[, col2])))) +
    xlab(paste(capitalize(col2))) +
    guides(fill = guide_legend(title = capitalize(col2))) +
    ggtitle(paste(capitalize(trait), " VS ", capitalize(col2)))

  print(p)
  ggsave(p, filename = file.path("Images", paste0(paste(trait, "VS", capitalize(col2), sep = "_"), ".png")), width = 10)
  ## dev.off()
}

## Diagnostic plots in base R graphics.
diagnostic.trait <- function(dfr, trait, col1, col2, treat1, treat2) {
  dir.create(file.path("Images", "Diagnostics"))
  ## Diagnostic plots for each trait
  diag.1 <- function(trait) {
    ## par(bg=rgb(1,1,0.8), mfrow=c(2,2))
    par(mfrow=c(2,2))
    qqnorm(eval(parse(text=trait)))
    qqline(eval(parse(text=trait)), col = 2)
    boxplot(eval(parse(text=trait)), horizontal = TRUE, main ="Box Plot", xlab=capitalize(trait))
    hist(eval(parse(text=trait)), main = "Histogram", xlab=capitalize(trait))
    plot(eval(parse(text=trait)), ylab = capitalize(trait), main = "Run Order Plot")
  }
  attach(dfr)
  diag.1(trait)
  png(file.path("Images", paste0(paste(trait, "diagnostic", "1", sep = "_"), ".png")), width = 1200, height = 900, res = 150)
  diag.1(trait)
  dev.off()

  ## Diagnostic plots for each trait by genotype (same as ggplot above but on one grid)
  factor1 <- col1
  factor2 <- col2
  diag.2 <- function(factor1, factor2, trait) {
    ## par(bg=rgb(1,1,0.8),mfrow=c(2,1))
    par(mfrow=c(2,1))
    boxplot(eval(parse(text=trait)) ~ eval(parse(text=factor1)),
      data=dfr, main=paste(capitalize(trait),"by", capitalize(factor1), sep=" "),
      xlab=capitalize(factor2), ylab=capitalize(trait))

    boxplot(eval(parse(text=trait)) ~ eval(parse(text=factor2)),
      data=dfr, main=paste(capitalize(trait),"by", capitalize(factor2), sep=" "),
      xlab=capitalize(factor2), ylab=capitalize(trait))
    par(mfrow=c(1,1))
  }
  diag.2(factor1, factor2, trait)
  png(file.path("Images", paste0(paste(trait, factor1, factor2, "diagnostic", "2", sep ="_"), ".png")), width = 1200, height = 900, res = 150)
  diag.2(factor1, factor2, trait)
  dev.off()
  detach(dfr)
}

## Creating a table of p values and n values
t.test.function <- function(dfr, trait, col1, col2, treat1, treat2) {
  t.values <- c()
  df.values <- c()
  p.values <- c()
  dn.values <- c()
  cn.values <- c()
  sig.values <- c()
  genos <- c()
  for( geno in as.character(unique(dfr[ , col1])) ) {
    control = dfr[dfr[, col1] == geno & dfr[, col2] == treat1, ][, trait]
    drought = dfr[dfr[, col1] == geno & dfr[, col2] == treat2, ][, trait]
    ## print(paste("T.test of Control vs Drought of ", geno, sep =""))
    test <- t.test(control, drought)
    t.values <- c(t.values, test$statistic[[1]])
    df.values <- c(df.values, test$parameter[[1]])
    p.values <- c(p.values, round(test$p.value, 4))
    dn.values <- c(dn.values, length(drought))
    cn.values <- c(cn.values, length(control))
    sig.values <- c(sig.values, ifelse(test$p.value < 0.05, "Yes", "No"))
    genos <- c(genos, geno)
  }
  final.data.frame <- data.frame(Genotype = genos, T.statistics = t.values, DF = df.values, P.values = p.values, Control.N = cn.values, Drought.N = dn.values, Significant = sig.values)
  return(final.data.frame)
}

pvalue.table <- function(dfr, trait, col1, col2, treat1, treat2) {
  final.data <- t.test.function(dfr, trait, col1, col2, treat1, treat2)
  return(final.data)
}

traits <- names(greenhouse.data.purged)
traits <- traits[c(6:length(traits))]
## traits <- traits[-grep("date", traits)]

genotypes <- sort(as.character(unique(greenhouse.data.purged$genotype)))

col1 <- "genotype"
col2 <- "treatment"
trait <- "plant_height_in1"
treat1 <- "100"
treat2 <- "50"
factor1 <- col1
factor2 <- col2
dfr <- greenhouse.data.purged
## dfr <- greenhouse.data.semi


pdf(file.path("Images", "all_trait_plots.pdf"), width = 10)
for(trait in traits) {
  analyze.trait(greenhouse.data.purged, trait, col1, col2, treat1, treat2)
}
dev.off()

pdf(file.path("Images", "all_diagnostic_plots.pdf"), width = 10)
for(trait in traits) {
  diagnostic.trait(greenhouse.data.purged, trait, col1, col2, treat1, treat2)
}
dev.off()

analyze.trait(greenhouse.data.purged, trait, col1, col2, treat1, treat2)


pdf(file.path("Images", "all_p_value_tables_per_trait.pdf"), width = 10)
for(trait in traits) {
  dir.create(file.path("Images", "Tables"))

  final <- pvalue.table(dfr, trait, col1, col2, treat1, treat2)
  final.matrix <- as.matrix(final)
  plot.table(final.matrix, trait, highlight = TRUE)
  png(file.path("Images", "Tables", paste0(paste(trait, col1, col2, treat1, treat2, sep ="_"), ".png")), width = 1200, height = 900, res = 150)
  plot.table(final.matrix, trait, highlight = TRUE)
  dev.off()
}
dev.off()

## Temporary for the moment
library(corrplot)
## Not quite necessary yet
test <- dfr[, c(6:length(dfr))]
test <- as.matrix(test)

# mat : is a matrix of data
# ... : further arguments to pass to the native R cor.test function
cor.mtest <- function(mat, ...) {
    mat <- as.matrix(mat)
    n <- ncol(mat)
    p.mat<- matrix(NA, n, n)
    diag(p.mat) <- 0
    for (i in 1:(n - 1)) {
        for (j in (i + 1):n) {
            tmp <- cor.test(mat[, i], mat[, j], ...)
            p.mat[i, j] <- p.mat[j, i] <- tmp$p.value
        }
    }
  colnames(p.mat) <- rownames(p.mat) <- colnames(mat)
  p.mat
}

M <- cor(test)
# matrix of the p-value of the correlation
p.mat <- cor.mtest(test)

corrplot.gh <- corrplot(M, method="pie", type = "lower",
  outline = TRUE, p.mat = p.mat, sig.level = 0.01, order = "hclust",
  insig = "blank", tl.srt = 45, tl.col = "black")

diag.corrplot <- function(dfr, treat.col, treatment, geno.col, genotype, ranges, order) {
  dfr <- dfr[dfr[, treat.col] %in% treatment, ]
  dfr <- dfr[dfr[, geno.col] %in% genotype, ]
  corr.matrix <- dfr[, ranges]
  M <- cor(corr.matrix)
  p.mat <- cor.mtest(M)
  corrplot.gh <- corrplot(M, method="pie", type = "lower",
    outline = TRUE, p.mat = p.mat, sig.level = 0.01, order = order,
    insig = "blank", tl.srt = 45, tl.col = "black")
  title(main = paste(capitalize(treat.col), paste(treatment, collapse = " and ")))
}

dfr <- greenhouse.data.purged
dfr[, grep("porometer", names(dfr))] <- list(NULL)
treatment <- 50
treat.col <- "treatment"
genotype <- unique(dfr[, "genotype"])
geno.col <- "genotype"
order <- "alphabet"
ranges <- c(6:length(dfr))

## Treatment of 50
diag.corrplot(dfr, treat.col, 50, geno.col, genotype, ranges, order)
## Treatment of 100
diag.corrplot(dfr, treat.col, 100, geno.col, genotype, ranges, order)
## All treatments
diag.corrplot(dfr, treat.col, c(100,50), geno.col, genotype, ranges, order)
