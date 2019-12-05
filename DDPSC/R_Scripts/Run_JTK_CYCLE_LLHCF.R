
source("JTK_CYCLEv3.1.R")

project <- "LLHCF"

options(stringsAsFactors=FALSE)
annot <- read.delim("LLHCF_annot.txt")
data <- read.delim("LLHCF_data.txt")

rownames(data) <- data[,1]
data <- data[,-1]
jtkdist(24, 2)       # 24 total time points, 2 replicates per time point

periods <- 10:14       # looking for rhythms between 20-28 hours (i.e. between 5 and 7 time points per cycle).
jtk.init(periods,2)  # 2 is the number of hours between time points

cat("JTK analysis started on",date(),"\n")
flush.console()

st <- system.time({
  res <- apply(data,1,function(z) {
    jtkx(z)
    c(JTK.ADJP,JTK.PERIOD,JTK.LAG,JTK.AMP)
  })
  res <- as.data.frame(t(res))
  bhq <- p.adjust(unlist(res[,1]),"BH")
  res <- cbind(bhq,res)
  colnames(res) <- c("BH.Q","ADJ.P","PER","LAG","AMP")
  results <- cbind(annot,res,data)
  results <- results[order(res$ADJ.P,-res$AMP),]
})
print(st)

save(results,file=paste("JTK",project,"rda",sep="."))
write.table(results,file=paste("JTK",project,"txt",sep="."),row.names=F,col.names=T,quote=F,sep="\t")

