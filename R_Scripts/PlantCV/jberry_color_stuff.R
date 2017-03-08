#*************************************************************************************************
# Getting color data from single channel
#*************************************************************************************************
getColor <- function(channel){
  cmd <- paste("grep ",channel," plantcv_imgtypeVIS_cameraSV_signal.tab | sed \'s/|/ /g\' | sed \'s/,/ /g\'",sep = "")
  data_out <- read.table(text=system(cmd,intern = T),colClasses = c("integer","integer","character",rep("numeric",256)))
  names(data_out) <- c("PlantID","Max","Color",sapply(seq(from=0,to=255,by=1),function(i) paste("h",i,sep="")))
  data_out <- join(assoc,join(sv_meta,data_out,by="PlantID",type="right"),by="Barcodes")
  data_out$DAP <- as.integer(sapply(data_out$Time,function(i) strsplit(strsplit(as.character(i)," ")[[1]][1],"-")[[1]][3]))-3
  outliers <- read.csv("sorg_outliers_cooks5timesmean.csv",header = T)
  data_out <- data_out[!(data_out$PlantID %in% outliers$PlantID),]
  data_out[,12:(ncol(data_out)-1)] <- t(apply(data_out[,12:(ncol(data_out)-1)],1,function(i){rescale(i,from=c(0,sum(i)))}))*100
  return(data_out)
}
my_col <- "hue"
channel <- getColor(my_col)
head(channel)


#*************************************************************************************************
# make HUE ONLY PCA to separate treatment groups
#*************************************************************************************************
makePCA <- function(data,day){
  sub <- data[data$DAP==day,]
  channel.pca <- PCA(sub[,32:(ncol(sub)-77)],graph = F)
  pca_df <- data.frame("Treatment"=ordered(sub$Treatment,levels=c(10,50,100)),
                     "PC1"=channel.pca$ind$coord[,1],
                     "PC2"=channel.pca$ind$coord[,2])
  varexp <- signif(c(channel.pca$eig[1,2],channel.pca$eig[2,2]),4)
  
  p <- ggplot(data=pca_df, aes(PC1,PC2))+
    geom_point(data=aggregate(cbind(PC1,PC2)~Treatment,pca_df,mean),aes(color=Treatment),size=5)+
    stat_ellipse(aes(fill=Treatment,color=Treatment),geom = "polygon",alpha=0.25)+
    ylim(c(-10,10))+
    xlim(c(-10.2,10))+
    xlab(paste("PC1 (",varexp[1],"%)",sep = ""))+
    ylab(paste("PC2 (",varexp[2],"%)",sep = ""))+
    scale_color_manual(values = c(muted("orange",l=30,c=100),muted("green",l=30,c=100),muted("purple",l=40,c=100)))+
    scale_fill_manual(values = c("orange",muted("green",l=30,c=100),"purple"))+
    geom_vline(xintercept = 0,linetype="dashed")+
    geom_hline(yintercept = 0,linetype="dashed")+
    theme_minimal()+
    theme(axis.text = element_text(size = 14),
          axis.title= element_text(size = 18))+
    theme(panel.border = element_rect(colour = "gray60", fill=NA, size=1,linetype = 1))
  p
}
p <- makePCA(channel,beginning)
p
ggsave("sorg_nitrogen_hue_beginning_bi_plot.png", width=7.22,height=6.15,plot = p, dpi = 300)
									
									
#*************************************************************************************************
# Get Average Histogram for each genotype at particular day
#*************************************************************************************************
hist_avg <- function(data,day){
  sub <- data[data$DAP==day,]
  test <- data.frame(do.call("rbind",lapply(split(sub,sub$Treatment),function(t){
    avgs <- data.frame(do.call("rbind",lapply(split(t,t$Line_name),function(g){
      colMeans(g[,12:(ncol(g)-1)])})
    ))
  })))
  return(test)
}
									
#*************************************************************************************************
# Get SD Histogram for each genotype at particular day
#*************************************************************************************************
hist_sd <- function(data,day){
  sub <- data[data$DAP==day,]
  test <- data.frame(do.call("rbind",lapply(split(sub,sub$Treatment),function(t){
    avgs <- data.frame(do.call("rbind",lapply(split(t,t$Line_name),function(g){
      apply(g[,12:(ncol(g)-1)],2,function(i){sd(i)/sqrt(length(i))})})
    ))
  })))
  return(test)
}
									

#*************************************************************************************************
# Plot treatment color histograms
#*************************************************************************************************
plot_histo <- function(x,y,color=my_col,day=""){
  sub <- channel[channel$DAP==day & channel$Treatment %in% c(10,100),]
  test <- hist_avg(sub,day)
  test_sd <- hist_sd(sub,day)
  
  if(color=="hue"){
    df <- data.frame("one"=t(test[x,1:180]),"two"=t(test[y,1:180]),"bin"=0:179*2)
    genotype <- strsplit(x,"[.]")[[1]][2]
    names(df) <- c("10","100","bin")
    df <- melt(df,id="bin")
    df$variable <- ordered(df$variable,levels=c("100","10"))
    
    df_sd <- data.frame("one"=t(test_sd[x,1:180]),"two"=t(test_sd[y,1:180]),"bin"=0:179*2)
    genotype <- strsplit(x,"[.]")[[1]][2]
    names(df_sd) <- c("10","100","bin")
    df_sd <- melt(df_sd,id="bin")
    df_sd$variable <- ordered(df_sd$variable,levels=c("100","10"))
    
    df$sd <- df_sd$value
    limits <- aes(ymax = value + 1.96*sd, ymin=value - 1.96*sd)
    
    ggplot(data=df,aes(bin,value))+
      ggtitle(paste(as.character(genotype)," (Day ",day,")",sep="",collapse = ""))+
      facet_wrap(~variable)+
      geom_ribbon(limits,fill="gray80")+
      geom_line(aes(color=bin),size=2)+
      scale_color_gradientn(colors=hue_pal(l=65)(180))+
      scale_x_continuous(breaks=number_ticks(5),limits = c(0,120))+
      scale_y_continuous(limits = c(0,12))+
      ylab("Percentage of Mask Explained")+
      xlab("")+
      #xlab("Hue Channel")+
      theme_light()+
      theme(legend.position='none')+
      theme(plot.title = element_text(hjust = 0.5),
            strip.background=element_rect(fill="gray50"),
            strip.text.x=element_text(size=14,color="white"),
            strip.text.y=element_text(size=14,color="white"))
  }else{
    df <- data.frame("one"=t(test[x,]),"two"=t(test[y,]),"bin"=0:255)
    df[,1] <- 1-(max(df[,1])-df[,1])/(max(df[,1])-min(df[,1]))
    df[,2] <- 1-(max(df[,2])-df[,2])/(max(df[,2])-min(df[,2]))
    genotype <- strsplit(x,"[.]")[[1]][2]
    names(df) <- c("10","100","bin")
    df <- melt(df,id="bin")
    df$variable <- ordered(df$variable,levels=c("100","10"))
    
    if(color=="nir"){
      ggplot(data=df,aes(bin,value))+
        ggtitle(as.character(genotype))+
        facet_wrap(~variable)+
        geom_line(size=2,color="black")+
        scale_x_continuous(breaks=number_ticks(5))+
        ylab("Relative Abundence")+
        xlab("NIR Channel")+
        theme_light()+
        theme(legend.position='none')+
        theme(strip.background=element_rect(fill="gray50"),
              strip.text.x=element_text(size=14,color="white"),
              strip.text.y=element_text(size=14,color="white"))
    }else{
      ggplot(data=df,aes(bin,value))+
        ggtitle(as.character(genotype))+
        facet_wrap(~variable)+
        geom_line(aes(color=bin),size=2)+
        scale_color_gradientn(colors=c('black',color))+
        scale_x_continuous(breaks=number_ticks(5))+
        ylab("Relative Abundence")+
        xlab(paste(lapply(strsplit("red",""),function(i){paste(toupper(i[1]),paste(i[-1],collapse = ""),sep="")})[[1]],"Channel",sep = " "))+
        theme_light()+
        theme(legend.position='none')+
        theme(strip.background=element_rect(fill="gray50"),
              strip.text.x=element_text(size=14,color="white"),
              strip.text.y=element_text(size=14,color="white"))
    }
  }} #TWO PANELS
p <- plot_histo("10.San Chi San","100.San Chi San",color = my_col,day=14)
p
									
									
#*************************************************************************************************
# Plot difference of two histograms
#*************************************************************************************************
histoDiff <- function(x,y,color,day){
  sub <- channel[channel$DAP==day & channel$Treatment %in% c(10,100),]
  test <- hist_avg(sub,day)
  test_sd <- hist_sd(sub,day)

  if(color=="hue"){
    df <- data.frame("one"=t(test[x,1:180]),"two"=t(test[y,1:180]),"bin"=0:179*2)
    df_sd <- data.frame("one"=t(test_sd[x,1:180]),"two"=t(test_sd[y,1:180]))
    
    #df[,1] <- 1-(max(df[,1])-df[,1])/(max(df[,1])-min(df[,1]))
    #df[,2] <- 1-(max(df[,2])-df[,2])/(max(df[,2])-min(df[,2]))
    genotype <- strsplit(x,"[.]")[[1]][2]
    #genotype <- "B.Az9504"
    names(df) <- c("10","100","bin")
    df$diff <- df$`10` - df$`100`
    df$sd <- apply(df_sd,1,mean)
    df$Title <- "Difference"
    print(tail(df))
    limits <- aes(ymax = diff + 1.96*sd, ymin=diff - 1.96*sd)
    

    ggplot(data=df,aes(bin,diff))+
      facet_wrap(~Title)+
      #ggtitle(as.character(genotype))+
      geom_ribbon(limits,fill="gray80")+
      geom_line(aes(color=bin),size=2)+
      scale_color_gradientn(colors=hue_pal(l=65)(180))+
      scale_x_continuous(breaks=number_ticks(5),limits = c(0,120))+
      scale_y_continuous(limits = c(-8,8))+
      ylab("(10 - 100)")+
      xlab("Hue Channel")+
      theme_light()+
      theme(legend.position='none')+
      theme(plot.title = element_text(hjust = 0.5),
            strip.background=element_rect(fill="gray50"),
            strip.text.x=element_text(size=14,color="white"),
            strip.text.y=element_text(size=14,color="white"))
  }else{
    print("haven't done anything with any other channel")
  }  
}
d <- histoDiff("10.Atlas","100.Atlas",color = my_col,day=14)
									
d <- histoDiff(c1,c2,color = my_col,day=day)
p <- plot_histo(c1,c2,color = my_col,day=day)
b <- grid.arrange(p, arrangeGrob(d), ncol = 1)									