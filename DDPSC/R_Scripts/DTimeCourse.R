file <- "ShootDTimeCourse.csv"
raw.data <- read.csv(file)
temp.data <- raw.data
# Getting data columns
col.list <- c(4:length(names(raw.data)))
# Converting columns to numeric
temp.data[, col.list] <- apply(raw.data[, col.list], 2, as.numeric)
# Getting the initial weight of the time course
initial.weight <- temp.data[, "X0"]
# Subtracting everything by the initial weight and making them column vectors
diff.cols <- t(apply(raw.data[, col.list], 1, function(x) { sapply(x, function(y) { y - head(x, n = 1) } ) } ))
# Making new data frame with the subtracted initial weight.
temp.data[, col.list] <- diff.cols
# Re-creating initial weight column for further calculations
temp.data[, "initial.weight"] <- initial.weight
# Saving data frame intermediary.
diff.data <- temp.data
col.list <- c(4:length(names(diff.data)))
# Getting the value of the subtracted weights over the initial weight aka  (w_t - w_t0) / w_t0 [w is weight, t is time]
avg.cols <- t(apply(diff.data[, col.list], 1, function(x) { sapply(x, function(y) { abs(y / tail(x, n=1)) } )} ))
temp.data[, col.list] <- avg.cols
temp.data[, "initial.weight"] <- initial.weight
# Saving data frame intermediary
rwdiff.data <- temp.data
# Initial weight is no longer necessary
temp.data <- temp.data[, !(names(temp.data) %in% "initial.weight")]
# Making an initial timepoint column
col.list <- c(4:length(names(temp.data)))
initial.time <- as.numeric(gsub("X", "", names(temp.data)[col.list]))
temp.data[1, ] <- c(names(temp.data)[-col.list], initial.time)
# Dividing the relative weight difference by the time point
time.cols <- apply(temp.data[, col.list], 2, function(x) { sapply(x, function(y) { as.numeric(y) / as.numeric(x[1]) } ) } )
temp.data[, col.list] <- time.cols
temp.data <- temp.data[-c(1), -c(4)]
# Saving data frame intermediary.
final.data <- temp.data
rownames(final.data) <- 1:nrow(final.data)

