#!/usr/bin/Rscript
library(tidyr)
library(argparser, quietly = TRUE)

p <- arg_parser("Take files, a single file, or a directory then a directory path (for files) and an output filename to summarize FastQC")
p <- add_argument(p,
                  arg = "--input",
                  help = "Give a space separated list of files, a single file, or a directory path",
                  type = "character",
                  nargs = Inf,
                  short = "-i")
p <- add_argument(p,
                  arg = "--directory",
                  help = "Directory path where multiple files reside if multiple space separated files given",
                  type = "character",
                  short = "-d")
p <- add_argument(p,
                  arg = "--filename",
                  help = "Output filename for the FastQC Summarized output",
                  short = "-f")

args <- parse_args(p)
filename <- args$filename
directory <- args$directory
files <- args$input
nameFlag <- FALSE
fileFlag <- FALSE

if(is.na(filename) | filename == "") {
    nameFlag <- TRUE
    print("Please provide a filename")
} else if (is.na(files) | files == "") {
    fileFlag <- TRUE
    print("Please provide an input")
}

if(fileFlag | nameFlag) {
    quit()
}


## options(echo=TRUE)
## args <- commandArgs(trailingOnly = TRUE)
## directory <- tail(args, n = 2)[[1]]
## filename <- tail(args, n = 2)[[2]]
## print(paste0("This is the filename: ", filename))
## files <- args[1:(length(args)-2)]
## print(paste0("This is the current directory: ", getwd()))

## print(files)

analyse.fastQC <- function(zip, debug = FALSE) {
    fastqc.zip <- zip
    fastqc.folder <- gsub(".zip", "", basename(fastqc.zip))
    if(debug) {
        print(paste0("This is the zip file: ", fastqc.zip))
        print(paste0("This is the fastqc_folder: ", fastqc.folder))
    }
    
    fastqc.data <- readLines(unz(fastqc.zip, file.path(fastqc.folder, "fastqc_data.txt")))
    fastqc.summary <- read.table(unz(fastqc.zip, file.path(fastqc.folder, "summary.txt")),
                                 header = F, sep = "\t", colClasses = rep("character", 3))
    fastqc.summary <- fastqc.summary[, c(3,2,1)]
    names(fastqc.summary) <- c("Library", "Variable", "Value")
    closeAllConnections()

    ## Getting percentage of pass, fail, and warn
    percentages <- list(
        "Pass Percentage" = round((sum(fastqc.summary$Value == "PASS") / 12) * 100, 2),
        "Fail Percentage" = round((sum(fastqc.summary$Value == "FAIL") / 12) * 100, 2),
        "Warn Percentage" = round((sum(fastqc.summary$Value == "WARN") / 12) * 100, 2)
    )
    percentages <- as.data.frame(do.call(rbind, percentages))
    percentages[, "Variable"] <- rownames(percentages)
    rownames(percentages) <- seq(nrow(percentages))
    percentages[, "Library"] <- fastqc.summary[1, 1]
    percentages <- percentages[, c(3, 2, 1)]
    names(percentages) <- names(fastqc.summary)
    fastqc.summary <- rbind(fastqc.summary, percentages)
    single.fastqc <- spread(fastqc.summary, "Variable", "Value")[, c(1, 2, 3, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 7, 4, 16)]
    return(list(Summary = fastqc.summary, Single = single.fastqc))
}

multiple.files <- function(directory) {
    if(length(directory) == 1 & dir.exists(directory)) {
        files <- file.path(directory, grep("zip", dir(directory), val = T))
    }
    analyses <- lapply(files, function(file) {
        analyse.fastQC(file)
    })
    analyses.single <- do.call(rbind, lapply(seq_along(analyses), function(index) { analyses[[index]][[2]] }))
    analyses.long <- do.call(rbind, lapply(seq_along(analyses), function(index) { analyses[[index]][[1]] }))
    return(list(Summary = analyses.long, Single = analyses.single))
}

if(length(files) == 1) {
    if(dir.exists(files[[1]])) {
        analyses.single <- multiple.files(files[[1]])
    }
    else {
        analyses.single <- analyse.fastQC(files[[1]])
    }
} else {
    ## files <- file.path(directory, files)
    analyses.single <- multiple.files(files[[1]])
}
write.table(analyses.single$Single, file = filename, quote = FALSE, sep = ",", row.names = FALSE)



