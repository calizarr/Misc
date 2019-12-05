library(data.table)
library(reshape)
library(parallel)
############################## Read all tabs ####################
## Reading in headers extracted from the sqlite database
features <- read.csv("features.csv")
metadata <- read.csv("metadata.csv")
directory <- getwd()

## Retrieving snapshot IDs from the database...? TAB FILES!
metadata.df <- lapply(grep("plantcv.*metadata", dir(directory), val = T), read.table, sep = "|", stringsAsFactors = FALSE)
metadata.df <- do.call(rbind, metadata.df)
names(metadata.df) <- names(metadata)
## Creating features data frame for the hell of it
features.df <- lapply(grep("plantcv.*features", dir(directory), val = T), read.table, sep = "|", stringsAsFactors = FALSE)
features.df <- do.call(rbind, features.df)
names(features.df) <- names(features)
## The joined data frame
joined.df <- merge(metadata.df, features.df, by = "image_id")
## Removing columns where all rows are 0
joined.df <- joined.df[, as.logical(colSums(joined.df != 0))]
vis.df <- joined.df[joined.df[, "imgtype"] == "VIS", ]
nir.df <- joined.df[joined.df[, "imgtype"] == "NIR", ]
## remove <- "image_id|run_id|lifter|gain|measurementlabel|cartag|id$|exposure|other|treatment|other"
## vis.df <- vis.df[, -grep(remove, colnames(vis.df))]
## nir.df <- nir.df[, -grep(remove, colnames(nir.df))]

vis.dt <- data.table(vis.df, key = "timestamp")
snapshots <- unique(vis.df[, "timestamp"])
## snapshots <- snapshots[1:5]

options(mc.cores = 4)
plantcv.data <- mclapply(snapshots, function(snap) {
    ## sub <- vis.dt[vis.dt$timestamp == snap, ]
    sub <- vis.dt[J(snap)]
    ## sub[sub$frame == "none", ]$frame <- 0
    sub[frame == "none", frame := 0]

    rows <- lapply(1:nrow(sub), function(row.idx) {
        row <- sub[row.idx, ]
        regex <- "^(?!(timestamp|treatment|measurementlabel|plantbarcode))"
        names(row) <- gsub(regex, paste0(tolower(row$camera), row$frame, "_", "\\1"), names(row), perl = T)
        return(row)
    })
    merge_recurse(rows, by = "timestamp")
})
plantcv.data <- do.call(rbind, plantcv.data)

write.csv(plantcv.data, "test.csv", row.names = FALSE, quote = FALSE)
    
################################################## DON'T GO DOWN HERE ##################################################

## vis.snapshots <- unique(vis.df[, "timestamp"])
## nir.snapshots <- unique(nir.df[, "timestamp"])

## Zoom-calibration
## Zoom correction
############################################
zoom.lm <- lm(zoom.camera ~ zoom, data=data.frame(zoom=c(1,6000), zoom.camera=c(1,6)))

## Download data for a reference object imaged at different zoom levels
if (!file.exists('zoom_calibration_data.txt')) {
    download.file('http://files.figshare.com/2084101/zoom_calibration_data.txt',
                  'zoom_calibration_data.txt')
}

## Read zoom calibrartion data
z.data <- read.table(file="zoom_calibration_data.txt", sep="\t", header=TRUE)

## Calculate px per cm
z.data$px_cm <- z.data$length_px / z.data$length_cm

## Calculate area for each row
z.data$area_cm <- ifelse(z.data$reference == z.data$reference[[1]], (13.2*13.2), (13.2*3.7))

## Calculate px**2 per cm**2
z.data$px2_cm2 <- z.data$area_px / z.data$area_cm

## Convert LemnaTec zoom units to camera zoom units
z.data$zoom.camera <- predict(object = zoom.lm, newdata=z.data)

## Zoom correction for area
area.coef <- coef(nls(log(rel_area) ~ log(a * exp(b * zoom.camera)),
                      z.data, start = c(a = 1, b = 0.01)))
area.coef <- data.frame(a=area.coef[1], b=area.coef[2])
area.nls <- nls(rel_area ~ a * exp(b * zoom.camera),
                data = z.data, start=c(a=area.coef$a, b=area.coef$b))

## Zoom correction for length
len.poly <- lm(px_cm ~ zoom.camera + I(zoom.camera^2),
               data=z.data[z.data$camera == 'VIS SV',])

## Experimental zoom correction for area
area.poly <- lm(px2_cm2 ~ zoom.camera + I(zoom.camera^2),
                data = z.data)



## ## Retrieving unique timestamps to differentiate images
## snapshots <- unique(metadata.df[metadata.df$imgtype == "VIS", "timestamp"])
## for(snapshot in snapshots) {
##   data <- new.env()
##   ## data[["plantbarcode"]] <- ""
##   ## data[["timestamp"]] <- ""
##   ## for(feature in feature.names) {
##   ##   data[[feature]] <- ""
##   ## }

##   sub.joined <- joined.df[joined.df$timestamp == snapshot & joined.df$imgtype == "VIS", ]
##   for(row.idx in nrow(sub.joined)) {
##     row <- sub.joined[row.idx, ]
##     data[["plantbarcode"]] <- row[["plantbarcode"]]
##     data[["timestamp"]] <- row[["timestamp"]]
##     row[["camera"]] <- tolower(row[["camera"]])

##     if (row[["frame"]] == "none") {
##       row[["frame"]] = "0"
##     }

##     for(feature in feature.names) {
##       data[[paste0(row[["camera"]], row[["frame"]], ".", feature)]] <- row[[feature]]
##     }

##     output <- vector("list", length(output.header))
##     names(output) <- output.header
##     for(field in output.header) {
##       if(!is.null(data[[field]])) {
##         output[[field]] <- data[[field]]
##       } else if(is.null(output[[field]])) {
##         output[[field]] <- NA
##       }
##     }
##   }
##   final.output <- rbind(final.output, output)
## }
## return(final.output)
