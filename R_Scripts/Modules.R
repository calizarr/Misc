library(plyr)
library(ggplot2)
library(dplyr)
library(reshape)
library(gridExtra)

single.nets <- "/home/hpriest/TBrutnell/forSarit/Updated"

## Function to retrieve module data based on Henry's data formats within his folder.
getModules <- function(species, net.path) {
    species.folder <- file.path(net.path, "SingleNets", paste0(species,".net.primary"))
    species.clusters <- file.path(species.folder, "Clusters")
    gen.mods <- lapply(dir(species.clusters), function(x) {
        genes <- scan(file.path(species.clusters, x), what = "character", quiet = TRUE)
        module <- gsub("Cluster\\.(\\d+)\\.txt", "\\1", x)
        module.vec <- rep(module, length(genes))
        return(data.frame(Target = genes, Module = module.vec))
    })
    gen.mods <- do.call(rbind, gen.mods)
    return(gen.mods)
}

## Function to retrieve expression data based on Henry's data formats within his folder.
getExpression <- function(species, net.path) {
    ## species.folder <- file.path(single.nets, paste0(species,".net.primary"))
    species.expression <- file.path(net.path, paste0(species, ".expression.all.tab"))
    expression <- read.csv(species.expression, sep = "\t", header = T)
    return(expression)
}

## Unfortunately, both Henry and I have named files differently in different places, so I need
## two vectors that represent named lists that have the names I am using.
species <- list( Maize = "Maize", Setaria = "Setaria", Sorghum = "Sorghum")
spec <- list(Maize = "Zmays", Setaria = "Sviridis", Sorghum = "Sbicolor")

## Getting the sample names and id that maps it to the expression map
samples <- lapply(spec, function(x) { read.csv(paste0(x, ".samples.csv"), header = F) })
expr.map <- lapply(spec, function(x) { read.csv(paste0(x, ".expression.map.csv"), header = F) })
## Getting the modules and expression data
gen.mods <- lapply(species, getModules, single.nets)
gen.expr <- lapply(species, getExpression, single.nets)

## Combining samples and expression map into one data frame
samples.expr.map <- lapply(species, function(x) {
    a <- merge(expr.map[[x]], samples[[x]], by.x = "V1", by.y = "V2")
    colnames(a) <- c("ID", "Field", "Sample")
    a <- a[, -1]
    return(a)
    })

## Adding replicate column to expression maps
## All Zmays start with Zm and a period then I need to find all alphabetical characters followed by one
## or more alphanumeric characters then either a - or a . and a may be there may be not r and finally the replicate digit
Zm <- gsub("Zm\\.[A-Za-z]\\w+[-.]r?(\\d+)","\\1", samples.expr.map[["Maize"]]$Sample)
## Sbicolor had a different problem. All beginnings are different BUT all replicate endings are mostly the same
## therefore match everything up until a - or _ then find one or more alphanumeric characters and then find a -
## after it should be the replicate number and finally match everything else just to make sure.
Sb <- gsub(".*[-_]\\w+-(\\d).*", "\\1", as.character(samples.expr.map[["Sorghum"]]$Sample))
## Setaria viridis had a similar but different problem. Some had the replicate at the beginning and some near the middle/end.
## The beginning ones capture the replicate immediately and then match everything else. If you don't match that then you match
## everything up until a - then capture the replicate then match everything else. Return both captured subgroups because one is
## the empty string.
Sv <- gsub("(\\d).*|.*-(\\d).*", "\\1\\2", as.character(samples.expr.map[["Setaria"]]$Sample))

samples.expr.map[["Maize"]][, "Replicate"] <- as.factor(Zm)
samples.expr.map[["Sorghum"]][, "Replicate"] <- as.factor(Sb)
samples.expr.map[["Setaria"]][, "Replicate"] <- as.factor(Sv)

## Fixing the sample names.
samples.expr.map[["Maize"]]$Sample <- as.factor(gsub("-", ".", as.character(samples.expr.map[["Maize"]]$Sample)))
samples.expr.map[["Sorghum"]]$Sample <- as.factor(gsub("-", ".", as.character(samples.expr.map[["Sorghum"]]$Sample)))
samples.expr.map[["Setaria"]]$Sample <- as.factor(gsub("-", ".", as.character(samples.expr.map[["Setaria"]]$Sample)))

## Fixing the Setaria Expression Matrix
## new.row <- as.list(as.character(gsub("X", "", colnames(gen.expr[["Setaria"]]))))
## new.row[[1]] <- "Sevir.Unknown"
## new.cols <- c("Target", as.character(samples.expr.map[["Setaria"]]$Sample))
## colnames(gen.expr[["Setaria"]]) <- new.cols
## gen.expr[["Setaria"]]$Target <- as.character(gen.expr[["Setaria"]]$Target)
## gen.expr[["Setaria"]] <- rbind(gen.expr[["Setaria"]], new.row)
## gen.expr[["Setaria"]]$Target <- as.factor(gen.expr[["Setaria"]]$Target)
new.cols <- gsub("X", "", colnames(gen.expr[["Setaria"]]))
colnames(gen.expr[["Setaria"]]) <- new.cols

## Mean-normalize the expression matrices.
gen.expr.mean <- lapply(species, function(x) {
    df <- gen.expr[[x]]
    rownames(df) <- df[, 1]
    df <- df[, -1]
    df <- as.matrix(df)
    df.mean <- apply(df, 1, function(y) {
        ## df[y, ] / mean(df[y,])
        y / mean(y)
    })
    df <- as.data.frame(t(df.mean))
    df[, "Target"] <- rownames(df)
    rownames(df) <- c(1:nrow(df))
    return(df)
})

## Melting the expression matrix into long format
gen.expr.melt <- lapply(species, function(x) {
    df <- gen.expr.mean[[x]]
    df <- melt(df)
    names(df) <- c("Target", "Sample", "Value")
    return(df)
})

## Joining the melted gene expression matrix and the sample expression map
gen.expr.map <- lapply(species, function(x) {
    df <- inner_join(gen.expr.melt[[x]], samples.expr.map[[x]], by = "Sample")
    return(df)
})

## Joining the modules to the gene expression sample matrix map
gen.expr.mods <- lapply(species, function(x) {
    df <- inner_join(gen.expr.map[[x]], gen.mods[[x]])
    ## leafs <- sort(gsub("-(\\d)$", "-0\\1", grep("Leaf-", levels(df$Field), val = T)))
    leafs <- grep("Leaf", levels(df$Field), val = T)
    leafs <- c(rev(grep("\\ -\\d", leafs, val = T)), grep("\\ \\+\\d$", leafs, val = T), grep("\\ \\+\\d\\d$", leafs, val = T))   
    ## bs <- gsub("-(\\d)$", "-0\\1", grep("BS-", levels(df$Field), val = T))
    bs <- grep("BS", levels(df$Field), val = T)
    ## ms <- gsub("-(\\d)$", "-0\\1", grep("M-", levels(df$Field), val = T))
    ms <- grep("M", levels(df$Field), val = T)
    ## df$Field <- factor(gsub("-(\\d)$", "-0\\1", as.character(df$Field)), c(leafs, bs, ms))
    df$Field <- factor(as.character(df$Field), levels = c(leafs, bs, ms))
    return(df)
})

## Plotting all of the modules
saved.plots <- lapply(species, function(sp) {
    a <- gen.expr.mods[[sp]]
    a.agg <- a %>% group_by(Target, Field, Module) %>% summarize(Mean.Val = mean(Value))
    mod.dir <- paste0(sp, "_Modules")
    dir.create(mod.dir)
    sp.plots <- lapply(sort(unique(a.agg$Module)), function(mod) {
        df.sub <- a.agg[a.agg$Module == mod, ]
        df.sub <- droplevels(df.sub)
        leafs <- grep("Leaf", levels(df.sub$Field), val = T)
        BS <- grep("BS", levels(df.sub$Field), val = T)
        MS <- grep("M", levels(df.sub$Field), val = T)
        df.leaf <- droplevels(df.sub[df.sub$Field %in% leafs, ])
        df.BS <- droplevels(df.sub[df.sub$Field %in% BS, ])
        df.MS <- droplevels(df.sub[df.sub$Field %in% MS, ])
        col.leaf <- "red"
        col.bs <- "blue"
        col.ms <- "green"
        col.vec <- ifelse(grepl("Leaf", levels(df.sub$Field)), col.leaf,
                   ifelse(grepl("BS", levels(df.sub$Field)), col.bs, col.ms))
        p <- ggplot(df.sub, aes(x = Field, y = Mean.Val, group = Target)) +
            geom_line(alpha = 0.001) +
            geom_line(aes(x = Field, y = Mean.Val), df.leaf, alpha = 0.1) +
            geom_line(aes(x = Field, y = Mean.Val), df.BS, alpha = 0.1) +
            geom_line(aes(x = Field, y = Mean.Val), df.MS, alpha = 0.1) +
            annotate("rect", xmin = df.leaf$Field[1],
                     xmax = df.leaf$Field[length(df.leaf$Field)],
                     ymin = min(df.leaf$Mean.Val), ymax = max(df.leaf$Mean.Val), alpha = 0.2, fill = col.leaf) +
            annotate("rect", xmin = df.BS$Field[1],
                     xmax = df.BS$Field[length(df.BS$Field)],
                     ymin = min(df.BS$Mean.Val), ymax = max(df.BS$Mean.Val), alpha = 0.2, fill = col.bs) +
            annotate("rect", xmin = df.MS$Field[1],
                     xmax = df.MS$Field[length(df.MS$Field)],
                     ymin = min(df.MS$Mean.Val), ymax = max(df.MS$Mean.Val), alpha = 0.2, fill = col.ms) +
            labs(x = "Sample", y = "Mean Normalized TPM", title = paste0("Module ", mod)) +
            theme_bw() +
            theme(
                ## panel.background=element_rect(fill="white"),
                axis.title.x = element_text(size = 20, face = "bold", margin = margin(20, 0, 0, 0)),
                axis.title.y = element_text(size = 20, face = "bold", margin = margin(0, 20, 0, 0)),
                axis.text.x = element_text(size = 15, angle = 90, vjust = 0, color = col.vec),
                axis.text.y = element_text(size = 15),
                plot.title = element_text(size = 20, face = "bold", hjust = 0.5)
                ## legend.text = element_text(size = 15, face = "bold"),
                ## legend.title = element_text(size = 15, face = "bold")
            )
        file.name <- paste0(sp, "_module", mod, "_meanNorm", ".png")
        ggsave(file.path(mod.dir, file.name), p)
        return(p)
    })
    return(sp.plots)
})
names(saved.plots) <- species

sp.plots <- lapply(species, function(sp) {
    plots <- saved.plots[[sp]]
    plots.adj <- lapply(plots, function(p) {
        p <- p +
            theme_bw() +
            theme(
                ## panel.background=element_rect(fill="white"),
                axis.title.x = element_text(size = 5, face = "bold"),
                axis.title.y = element_text(size = 5, face = "bold"),
                axis.text.x = element_text(size = 4, angle = 90, vjust = 0,
                                           color = p$theme$axis.text.x$colour),
                axis.text.y = element_text(size = 4),
                plot.title = element_text(size = 5, face = "bold", hjust = 0.5)
                ## legend.text = element_text(size = 15, face = "bold"),
                ## legend.title = element_text(size = 15, face = "bold")
            )
        return(p)
    })
    return(plots.adj)
})
names(sp.plots) <- species

lapply(species, function(x) {
    ncol <- 3
    nrow <- 3
    ml <- marrangeGrob(sp.plots[[x]], ncol = ncol, nrow = nrow)
    dir.name <- paste0(x, "_Modules")
    file.name <- paste0(x, "_Modules_", ncol, "x", nrow, ".pdf")
    ggsave(file.path(dir.name, file.name), ml)
})


#################### TESTING ########################################

a <- gen.expr.mods[["Maize"]]
a.agg <- a %>% group_by(Target, Field, Module) %>% summarize(Mean.Val = mean(Value))
a.all <- a.agg
a.agg <- a.all[a.all$Module %in% seq(1,10), ]

leafs <- grep("Leaf-", levels(a.agg$Field), val = T)
BS <- grep("BS", levels(a.agg$Field), val = T)
MS <- grep("M-", levels(a.agg$Field), val = T)

a.leaf <- droplevels(a.agg[a.agg$Field %in% leafs, ])
a.BS <- droplevels(a.agg[a.agg$Field %in% BS, ])
a.MS <- droplevels(a.agg[a.agg$Field %in% MS, ])
col.leaf <- "red"
col.bs <- "blue"
col.ms <- "green"
col.vec <- ifelse(grepl("Leaf", levels(df.sub$Field)), col.leaf,
           ifelse(grepl("BS-", levels(df.sub$Field)), col.bs, col.ms))

p <- ggplot(a.agg, aes(x = Field, y = Mean.Val, group = Target)) +
    geom_line(alpha = 0.001) +
    geom_line(aes(x = Field, y = Mean.Val), a.leaf, alpha = 0.1) +
    geom_line(aes(x = Field, y = Mean.Val), a.BS, alpha = 0.1) +
    geom_line(aes(x = Field, y = Mean.Val), a.MS, alpha = 0.1) +
    annotate("rect", xmin = a.leaf$Field[1],
             xmax = a.leaf$Field[length(a.leaf$Field)],
             ymin = min(a.leaf$Mean.Val), ymax = max(a.leaf$Mean.Val), alpha = 0.2, fill = "red") +
    annotate("rect", xmin = a.BS$Field[1],
             xmax = a.BS$Field[length(a.BS$Field)],
             ymin = min(a.BS$Mean.Val), ymax = max(a.BS$Mean.Val), alpha = 0.2, fill = "blue") +
    annotate("rect", xmin = a.MS$Field[1],
             xmax = a.MS$Field[length(a.MS$Field)],
             ymin = min(a.MS$Mean.Val), ymax = max(a.MS$Mean.Val), alpha = 0.2, fill = "green") +
    labs(x = "Sample", y = "Mean Normalized TPM", title = paste0("Module ", mod)) +
    theme_bw() +
    theme(
        ## panel.background=element_rect(fill="white"),
        axis.title.x = element_text(size = 20, face = "bold", margin = margin(20, 0, 0, 0)),
        axis.title.y = element_text(size = 20, face = "bold", margin = margin(0, 20, 0, 0)),
        axis.text.x = element_text(size = 15, angle = 90, vjust = 0, color = col.vec),
        axis.text.y = element_text(size = 15),
        plot.title = element_text(size = 20, face = "bold", hjust = 0.5)
        ## legend.text = element_text(size = 15, face = "bold"),
        ## legend.title = element_text(size = 15, face = "bold")
    ) +
    facet_wrap(~ Module)

ggsave("test.png", p, units = "in", height = 11, width = 11)
