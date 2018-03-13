## Convert Kallisto outputs to JTK Cycle inputs
files <- dir()[grep("tsv", dir())]
treatments <- unique(sapply(files, function(x) { strsplit(x, "_")[[1]][c(1:3)] }))
colnames(treatments) <- c()
zts <- unique(treatments[dim(treatments)[1], c(1:dim(treatments)[2])])
reps <- unique(treatments[dim(treatments)[1]-1, c(1:dim(treatments)[2])])
exps <- unique(treatments[dim(treatments)[1]-2, c(1:dim(treatments)[2])])

get.length <- nrow(read.csv(files[1], sep = "\t"))
final <- data.frame(c(1:get.length))
col.names <- c()
exp.names <- c()


for( ex in exps ) {
    s.files <- files[grep(ex, files)]
    for( zt in zts ) {
        sa.files <- s.files[grep(zt, s.files)]
        for ( rp in reps ) {
            sb.files <- sa.files[grep(rp, sa.files)]
            kallisto <- read.csv(sb.files, sep = "\t")
            col.name <- paste(toupper(zt), rp, sep="_")
            probe <- as.character(kallisto$target_id)
            values <- kallisto$tpm
            col.names <- c(col.names, col.name)
            exp.names <- c(exp.names, ex)
            final <- cbind(final, values)
        }
    }
}

## lapply(exps, function(ex) {
##     s.files <- files[grep(ex, files)]
##     paste0("Done with experiment: ", ex)
##     lapply(zts, function(zt) {
##         sa.files <- s.files[grep(zt, s.files)]
##         paste0("Done with zt time: ", zt)
##         lapply(reps, function(rp) {
##             sb.files <- sa.files[grep(rp, sa.files)]
##             sb.files <- sa.files[grep(rp, sa.files)]
##             kallisto <- read.csv(sb.files, sep = "\t")
##             col.name <- paste(toupper(zt), rp, sep="_")
##             probe <- as.character(kallisto$target_id)
##             values <- kallisto$tpm
##             col.names <- c(col.names, col.name)
##             exp.names <- c(exp.names, ex)
##             final <- cbind(final, values)
##             paste0("Done with rep: ", rp)
##         }
##         )
##     }
##     )
## }
## )
            
final[,names(final)[1]] <- NULL
colnames(final) <- col.names

ldhhf.df <- final[, grep(exps[1], exp.names)]
llhcf.df <- final[, grep(exps[2], exp.names)]

ldhhf.df <- cbind(probe, ldhhf.df)
names(ldhhf.df)[1] <- "Probe"
llhcf.df <- cbind(probe, llhcf.df)
names(llhcf.df)[1] <- "Probe"

probe <- c("Probe", probe)

write.table(ldhhf.df, paste(exps[1], "_data.txt", sep =""), sep = "\t", row.names = FALSE, quote = FALSE)
write.table(probe, paste(exps[1], "_annot.txt", sep = ""), sep = "\t", row.names = FALSE, quote = FALSE, col.names = FALSE)
write.table(llhcf.df, paste(exps[2], "_data.txt", sep =""), sep = "\t", row.names = FALSE, quote = FALSE)
write.table(probe, paste(exps[2], "_annot.txt", sep = ""), sep = "\t", row.names = FALSE, quote = FALSE, col.names = FALSE)
