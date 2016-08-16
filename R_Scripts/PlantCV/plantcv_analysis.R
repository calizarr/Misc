#################### PlantCV Output Analysis Script ####################################
source("plantcv_analysis_helper.R")

########################################################################################
# Analyze VIS data
########################################################################################

############################################
# Read data and format for analysis
############################################
# Filenames
snapshot.file <- "SnapshotInfo.csv"
barcode.file <- "ENCODE_Run_1_barcodes.csv"
plantcv.file <- "ENCODE_Run_1_results.csv"

# Read VIS data
snapshot.data <- read.table(file=snapshot.file, sep=",", header=TRUE)
barcode.data <- read.table(file=barcode.file, sep =",", header=TRUE)
plantcv.data <- read.table(file=plantcv.file, sep = ",", header=TRUE)

## Fixing plantcv.data's plantbarcode header
## All the datasets require a column named genotype, treatment, and plantbarcode
names(plantcv.data)[1] <- "plantbarcode"
names(barcode.data) <- c("plantbarcode", "genotype", "treatment", "replicate")
names(snapshot.data)[3] <- "plantbarcode"

## Cleaning snapshot.data.
## Testing massive removal.

snapshot.data <- snapshot.data[, names(snapshot.data) %in% c("plantbarcode", "timestamp", "weight.before", "weight.after", "water.amount")]

snapshot.data <- snapshot.data[snapshot.data$weight.before != -1, ]

## Merging snapshot info and genotype treatment data from barcode.data, test to figure out which rows do not merge
snapshot.gt.data <- merge(barcode.data, snapshot.data, all = TRUE)
excluded <- snapshot.gt.data[rowSums(is.na(snapshot.gt.data)) > 0,]

## Fully merging once non-merged rows are inspected
snapshot.gt.data <- merge(barcode.data, snapshot.data, all = FALSE)

## Testing merging with plantcv.data and snapshot.gt.data
plantcv.gt.data <- merge(barcode.data, plantcv.data, all = TRUE)

excluded <- plantcv.gt.data[rowSums(is.na(plantcv.gt.data)) > 0, ]

## Fully merging once non-merged rows are inspected
plantcv.gt.data <- merge(barcode.data, plantcv.data, all = FALSE)

vis.data <- plantcv.gt.data

## Zoom-calibration
## Zoom correction
############################################
zoom.lm <- lm(zoom.camera ~ zoom, data=data.frame(zoom=c(1,6000), zoom.camera=c(1,6)))

# Download data for a reference object imaged at different zoom levels
if (!file.exists('zoom_calibration_data.txt')) {
  download.file('http://files.figshare.com/2084101/zoom_calibration_data.txt',
                'zoom_calibration_data.txt')
}

# Read zoom calibrartion data
z.data <- read.table(file="zoom_calibration_data.txt", sep="\t", header=TRUE)

# Calculate px per cm
z.data$px_cm <- z.data$length_px / z.data$length_cm

# Calculate area for each row
z.data$area_cm <- ifelse(z.data$reference == z.data$reference[[1]], (13.2*13.2), (13.2*3.7))

# Calculate px**2 per cm**2
z.data$px2_cm2 <- z.data$area_px / z.data$area_cm

# Convert LemnaTec zoom units to camera zoom units
z.data$zoom.camera <- predict(object = zoom.lm, newdata=z.data)

# Zoom correction for area
area.coef <- coef(nls(log(rel_area) ~ log(a * exp(b * zoom.camera)),
                     z.data, start = c(a = 1, b = 0.01)))
area.coef <- data.frame(a=area.coef[1], b=area.coef[2])
area.nls <- nls(rel_area ~ a * exp(b * zoom.camera),
               data = z.data, start=c(a=area.coef$a, b=area.coef$b))

# Zoom correction for length
len.poly <- lm(px_cm ~ zoom.camera + I(zoom.camera^2),
  data=z.data[z.data$camera == 'VIS SV',])

# Experimental zoom correction for area
area.poly <- lm(px2_cm2 ~ zoom.camera + I(zoom.camera^2),
  data = z.data)

# Convert LemnaTec zoom units to camera zoom units
vis.data$zoom <- vis.data$tv0_zoom
vis.data$zoom <- as.integer(gsub('z', '', vis.data$zoom))
vis.data$zoom.camera <- predict(object = zoom.lm, newdata = vis.data)
vis.data$rel_area <- predict(object = area.nls, newdata = vis.data)
vis.data$px_cm <- predict(object = len.poly, newdata = vis.data)
vis.data$px2_cm2 <- predict(object = area.poly, newdata = vis.data)

# Planting date
planting_date <- as.POSIXct("2015-09-04")

# Date-time from Unix time
vis.data$date <- as.POSIXct(vis.data$timestamp, origin = "1970-01-01")

# Days after planting
vis.data$dap <- as.numeric(vis.data$date - planting_date)
vis.data$day <- as.integer(vis.data$dap)

# Adjusted day for odd and even image days
vis.data$imageday <- 0
vis.data$imageday <- vis.data$day
vis.data[vis.data$day %% 2 == 0,]$imageday <- vis.data[vis.data$day %% 2 == 0,]$day-1

############################################
# Build traits table
############################################
traits <- data.frame(plantbarcode = vis.data$plantbarcode, timestamp = vis.data$timestamp,
  genotype = vis.data$genotype, treatment = vis.data$treatment, replicate = vis.data$replicate,
  dap = vis.data$dap, day = vis.data$day, imageday = vis.data$imageday)

## # Zoom correct TV and SV area
## traits$tv_area <- vis.data$tv0_area / vis.data$rel_area
## traits$sv_area <- (vis.data$sv0_area / vis.data$rel_area) +
##                  (vis.data$sv90_area / vis.data$rel_area)
## traits$area <- traits$tv_area + traits$sv_area

# Experimental zoom correct TV and SV area
traits$tv_area <- vis.data$tv0_area / vis.data$px2_cm2
traits$sv_area <- (vis.data$sv0_area / vis.data$px2_cm2) +
                 (vis.data$sv90_area / vis.data$px2_cm2)
traits$area <- traits$tv_area + traits$sv_area

# Zoom correct height
traits$height <- ((vis.data$sv0_height_above_bound / vis.data$px_cm) +
                    (vis.data$sv90_height_above_bound / vis.data$px_cm)) / 2

traits$group <- paste(traits$genotype,'-',traits$treatment,sep='')

barcodes <- unique(sort(traits$plantbarcode))

######################################## BEGIN: Outlier Detection And Removal #####################################

## Removing outliers.
## get the image dataset without outliers
## traits <- c("solidity", "sv_area", "tv_area", "extent_x", "extent_y", "height_above_bound", "wue", "volume")
trait.vec <- c("sv_area", "tv_area", "area", "height")
traits.out <- traits

for(trait in trait.vec) {
    traits.out[, trait][which(traits.out[, trait]==0)] <- NA
}

system.time(
dataset <- outlier.detection(traits.out, col.day="imageday", fill=TRUE)
    )

no.outliers <- sum(traits.out[, trait.vec]!=dataset[, trait.vec], na.rm=TRUE)

traits <- dataset

######################################## END: Outlier Detection And Removal #######################################

#################### Making an average of the replicates ####################
traits.avg <- aggregate(cbind(tv_area, sv_area, area, height)~genotype+treatment+day+imageday, traits, mean)

## Cool statement that can be used as internal function to pass and
## aggregate within function instead of creating many aggregate data frames
## dfr <- aggregate(as.formula(paste(x, " ~ genotype + treatment + day +imageday", sep = "")), dfr, mean)

######################################## BEGIN: Trait Plotting Function ###########################################

## Plot trait for each genotype
dir.create("pdf_images")
## pdf(file=file.path("pdf_images","all_height_day.pdf"),height=6,width=6, useDingbats=FALSE)
## pdf(file=file.path("pdf_images","all_area_day.pdf"),height=6,width=6, useDingbats=FALSE)
treatments <- unique(sort(as.character(traits$treatment)))
genotypes <- unique(sort(as.character(traits$genotype)))
for(genotype in genotypes) {
  ## plot.trait(traits, genotype, treatments, "imageday", "height", "(cm)", limits = c(0, 25))
  ## ggsave(paste0("images/",paste(genotype,"height","cm",sep="_"),".png"), dpi = 600)
  plot.trait(traits, genotype, treatments, "imageday", "area", "(cm^2)", limits = c(0, 300))
  ## ggsave(paste0("images/",paste(genotype,"area","cm^2",sep="_"),".png"),  dpi = 600)
}
## dev.off()

## Facet plot of all genotype traits.
plot.trait(traits, genotypes, treatments, "imageday", "height", "(cm)", limits = c(), facet = TRUE)
## plot.trait(traits, genotypes, treatments, "imageday", "area", "(cm^2)", limits = c(), facet = TRUE)

######################################## END: Trait Plotting Function #############################################

######################################## BEGIN: Heat Map Plotting #################################################

dir.create("pdf_images")
dir.create("images")

mean.ratio.area.90to22.5 <- trait.heatmap(traits.avg, "90", "22.5", "Ratio of 90 to 22.5", "area", "ratio",
  save = TRUE, save.name = "images/mean.ratio.area.90to22.5")

mean.ratio.area.90toDrought <- trait.heatmap(traits.avg, "90", "drought", "Ratio of 90 to Drought", "area", "ratio",
  save = TRUE, save.name = "images/mean.ratio.area.90toDrought")

mean.ratio.area.90to45 <- trait.heatmap(traits.avg, "90", "45", "Ratio of 90 to 45", "area", "ratio",
  save = TRUE, save.name = "images/mean.ratio.area.90to45")

mean.ratio.area.90toRecovery <- trait.heatmap(traits.avg, "90", "recovery", "Ratio of 90 to Recovery", "area", "ratio",
  save = TRUE, save.name = "images/mean.ratio.area.90toRecovery")

mean.ratio.area.90toPrimer <- trait.heatmap(traits.avg, "90", "primer", "Ratio of 90 to Primer", "area", "ratio",
  save = TRUE, save.name = "images/mean.ratio.area.90toPrimer")

######################################## END: Heat Map Plotting ###################################################

######################################## BEGIN: Water Use Efficiency Plots ########################################

water.data <- snapshot.gt.data

## Add a genotype x treatment group column.
water.data$group <- paste(water.data$genotype,'-',water.data$treatment,sep='')

## Add a column for days after planting since the planting date.
water.data$date <- as.POSIXct(water.data$timestamp, origin = "1970-01-01")
water.data$dap = as.numeric(water.data$date - planting_date)
water.data$day <- as.integer(water.data$dap)
water.data$imageday <- water.data$day
water.data[water.data$day %% 2 == 0,]$imageday <- water.data[water.data$day %% 2 == 0,]$day-1

## Fixing the initial watering amount of 0 to be 0.001 or 0.0001
## Not useful right now but maybe later
## water.data[water.data$water.amount < 1 & water.data$dap <= 22, ]$water.amount <- 1

test.water <- water.data[(water.data$treatment == "90" | water.data$treatment == "22.5") &
                       water.data$genotype == 'Bd21-0',]

wue.data <- wue.calculate(water.data, traits, genotypes, treatments, "area")
wue.data$group <- paste(wue.data$genotype,'-',wue.data$treatment,sep='')

wue.delta <- deltaWUE(wue.data, "area")
wue.delta$group <- paste(wue.delta$genotype,'-',wue.delta$treatment,sep='')

#################### WUE Plots ####################################

## Plot WUE for each genotype
## dir.create("pdf_images")
## pdf(file=file.path("pdf_images","all_wue.pdf"),height=6,width=6, useDingbats=FALSE)
pdf(file=file.path("pdf_images","all_delta_wue.pdf"),height=6,width=6, useDingbats=FALSE)
treatments <- unique(sort(as.character(traits$treatment)))
genotypes <- unique(sort(as.character(traits$genotype)))
for(genotype in genotypes) {
  ## WUE.plot(wue.data, "dap", "(water / area)", genotype, treatments, "Days After Planting",
  ##   "Water Use Efficiency", color.title = "Genotype-Treatment", main = paste0(capitalize(genotype)))
  ## ggsave(paste0("images/",paste(genotype,"wue","unitless",sep="_"),".png"), width = 8, height = 6, dpi = 300, pointsize = 8)
  WUE.plot(wue.delta, "dap", "(delta_water / delta_area)", genotype, treatments, "Days After Planting",
    "Delta-Water Use Efficiency", color.title = "Genotype-Treatment", main = paste0(capitalize(genotype)))
  ggsave(paste0("images/",paste(genotype,"wue_delta","unitless",sep="_"),".png"), width = 8, height = 6, dpi = 300, pointsize = 8)
}
dev.off()

######################################## BEGIN: Analysis Of Data ##################################################

## Get the mean and confidence interval of height per day
height.per.day.90 <- trait.per.day(traits, "height")

## Get the mean and confidence interval of area per day
area.per.day.90 <- trait.per.day(traits, "area")

## Get the trait differences per two days for each treatment specified
bd21.height.results <- analyze.trait(traits, "height", "Bd21-0", "90", "22.5")
bd1.height.results <- analyze.trait(traits, "height", "Bd1-1", "90", "22.5")

## Control for multiple testing by controlling the FDR
bd21.qvalues.height = p.adjust(bd21.height.results$pvalue, method="fdr")
bd1.qvalues.height = p.adjust(bd1.height.results$pvalue, method="fdr")


######################################## END: Analysis Of Data #####################################################


#################### Outputting final csv file ####################

