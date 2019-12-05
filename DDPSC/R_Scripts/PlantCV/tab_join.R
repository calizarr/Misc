############################## Read all tabs ####################

plantcv.features.read <- function(directory, tv = TRUE, sv = c(0, 90), imgtype = "VIS") {
  ## Reading in headers extracted from the sqlite database
  features <- read.csv("features.csv")
  metadata <- read.csv("metadata.csv")
  ## Creating the features vector
  feature.names <- c("zoom", names(features))
  ## Creating the full output vector
  output.header <- c("plantbarcode", "timestamp")
  ## If there are top view images create top view header and add to output header
  if(tv) {
    ## tv.header <- c("tv0.zoom")
    tv.header <- unname(sapply(feature.names, function(feature) { paste0("tv0.", feature) }))
    output.header <- c(output.header, tv.header)
  }
  ## If there are side-view images and angles: create several side view headers and add to output header
  if(length(sv) >= 1) {
    angles <- sv
    sv.header <- lapply(angles, function(angle) {
      sv.header <- unname(sapply(feature.names, function(feature) {
        paste0("sv", angle, ".", feature)
      }))
      return(sv.header)
    })
    output.header <- c(output.header, unlist(sv.header))
  }
  ## Here Noah would write out the output header, for now we keep it in our pocket and make an empty dataframe
  options("stringsAsFactors"=FALSE)
  final.output <- data.frame(matrix(ncol = length(output.header), nrow = 0))
  colnames(final.output) <- output.header
  ## Retrieving snapshot IDs from the database...? TAB FILES!
  metadata.df <- lapply(grep("plantcv.*metadata", dir(directory), val = T), read.table, sep = "|", stringsAsFactors = FALSE)
  metadata.df <- do.call(rbind, metadata.df)
  names(metadata.df) <- names(metadata)
  ## Creating features data frame for the hell of it
  features.df <- lapply(grep("plantcv.*features", dir(directory), val = T), read.table, sep = "|", stringsAsFactors = FALSE)
  features.df <- do.call(rbind, features.df)
  names(features.df) <- names(features)
  ## The joined data frame
  joined.df <- merge(features.df, metadata.df, by = "image_id")

  ## Retrieving unique timestamps to differentiate images
  snapshots <- unique(metadata.df[metadata.df$imgtype == "VIS", "timestamp"])
  for(snapshot in snapshots) {
    data <- new.env()
    ## data[["plantbarcode"]] <- ""
    ## data[["timestamp"]] <- ""
    ## for(feature in feature.names) {
    ##   data[[feature]] <- ""
    ## }

    sub.joined <- joined.df[joined.df$timestamp == snapshot & joined.df$imgtype == "VIS", ]
    for(row.idx in nrow(sub.joined)) {
      row <- sub.joined[row.idx, ]
      data[["plantbarcode"]] <- row[["plantbarcode"]]
      data[["timestamp"]] <- row[["timestamp"]]
      row[["camera"]] <- tolower(row[["camera"]])

      if (row[["frame"]] == "none") {
        row[["frame"]] = "0"
      }

      for(feature in feature.names) {
        data[[paste0(row[["camera"]], row[["frame"]], ".", feature)]] <- row[[feature]]
      }

      output <- vector("list", length(output.header))
      names(output) <- output.header
      for(field in output.header) {
        if(!is.null(data[[field]])) {
          output[[field]] <- data[[field]]
        } else if(is.null(output[[field]])) {
          output[[field]] <- NA
        }
      }
    }
    final.output <- rbind(final.output, output)
  }
  return(final.output)
}
