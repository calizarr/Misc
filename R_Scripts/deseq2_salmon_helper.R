makeResultsTables <- function(treatments = treatments, dds = dds, threads = 4, gene.symbols = gene.symbols) {
    dired <- paste0("Wald_Test_Pairwise")
    dir.create(dired)
    tables <- lapply(seq_along(treatments),
       function(x) {
           lapply(seq_along(treatments),
                  function(y) {
                      if (y <= x) {
                          NULL
                      } else {
                          res <- results(dds, alpha = 0.05, contrast=c("treatment", treatments[x], treatments[y]), parallel = TRUE)
                          res$symbol <- gene.symbols[gene.symbols$ens_gene %in% rownames(res), ]$ext_gene
                          mcols(res)$description[7] <- "Gene Symbol"
                          resOrdered <- res[order(res$padj), ]
                          sink(file.path(dired, paste0("Summary_", treatments[x], "_vs_", treatments[y], ".txt")))
                          print(summary(resOrdered))
                          sink()
                          resOrderedDF <- as.data.frame(resOrdered)
                          resOrderedDF$genes <- rownames(resOrderedDF)
                          resOrderedDF <- resOrderedDF[, c("symbol", setdiff(names(resOrderedDF), "symbol"))]
                          resOrderedDF <- resOrderedDF[, c("genes", setdiff(names(resOrderedDF), "genes"))]
                          write.csv(resOrderedDF,
                                    file = file.path(dired, paste0(treatments[x], "_vs_", treatments[y], "_comparisons_results.csv")),
                                    row.names = TRUE)
                          resOrdered
                      }
                  }
                  )
       }
       )
    tables <- rmNullObs(tables)
    return(tables)
}

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

## A helper function that tests whether an object is either NULL _or_
## a list of NULLs
is.NullOb <- function(x) is.null(x) | all(sapply(x, is.null))

## Recursively step down into list, removing all such objects
rmNullObs <- function(x) {
    x <- Filter(Negate(is.NullOb), x)
    lapply(x, function(x) if (is.list(x)) rmNullObs(x) else x)
}

## Subsetting to only do one treatment against the control per time course
## Functions
## Example usage: Subsetted sampleTable give it the rownames and it does the rest.
## txi.sub <- subset.txi(rownames(sTable), txi)
subset.txi <- function(grep.vals, txi) {
    lapply(txi, function(x) {
        if(length(x) != 1) {
            sub <- colnames(x) %in% grep.vals
            z <- x[, sub]
            return(z)
        } else {
            return(x)
        }
    }
    )
}
