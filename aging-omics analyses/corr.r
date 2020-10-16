mdoule = read.table("GutMeta2015a.module.module.LD.prof",sep = "\t",check.names = F,
                    stringsAsFactors = F,header = T,row.names = 1)
pathway = read.table("GutMeta2015a.pathway.pathway.LC.prof",sep = "\t",
                     check.names = F,stringsAsFactors = F,header = T,
                     row.names = 1)
mdoule = mdoule[,colnames(pathway)]
mdoule = rbind(mdoule,pathway)
mdoule_list = read.table("module_list.txt",
                         sep = "\t",check.names = F,
                         stringsAsFactors = F)
mdoule = mdoule[mdoule_list[,1],]
mdoule_list$name = mdoule_list$V2
row.names(mdoule) = mdoule_list$name
UT = read.table("UT.profile",sep= "\t",check.names = F,stringsAsFactors = F,
                header = T,row.names = 1)
UT = UT[,colnames(mdoule)]
BAI = read.table("BAI.profile",sep = "\t",check.names = F,
                 stringsAsFactors = F,header = T,row.names = 1)
BAI = BAI[,colnames(mdoule)]
mdoule =rbind(mdoule,UT,BAI)
BM = read.csv("../代谢组数据_new.txt",sep = "\t",check.names = F,
                stringsAsFactors = F,header = T,row.names = 1)
BM_list = read.table("met_list.txt",sep = "\t",check.names = F,
                     stringsAsFactors = F)
Med = read.table("../Med.txt",sep = "\t",check.names = F,
                 stringsAsFactors = F,header = T,row.names = 1)
BM =BM[,BM_list[,1]]
Med = Med[row.names(BM),]
mdoule = data.frame(t(mdoule),check.names = F,stringsAsFactors = F)
mdoule = mdoule[row.names(BM),]
#mdoule = mdoule[,!grepl("M00623",colnames(mdoule))]
library(ppcor)
corr_1 = function(a,b,d){
  cor_r = matrix(rep(0,ncol(a)*ncol(b)),ncol(a),ncol(b))
  row.names(cor_r) = colnames(a)
  colnames(cor_r) = colnames(b)
  cor_p = matrix(rep(0,ncol(a)*ncol(b)),ncol(a),ncol(b))
  row.names(cor_p) = colnames(a)
  colnames(cor_p) = colnames(b)
  for(i in 1:ncol(a)){
    for(j in 1:ncol(b)){
      cor_1 = pcor.test(as.double(a[,i]),as.double(b[,j]),d,method = "spearman")
      cor_r[i,j] = cor_1$estimate
      cor_p[i,j] = cor_1$p.value
    }
    print(i)
  }
  k = list(p = cor_p,r = cor_r)
  return(k) 
}


cor_r = corr_1(mdoule,BM,Med$Age)
cor_r_r =cor_r$r
cor_r_p = cor_r$p

library(gplots)
heat_map <- function(x,y){
  #x = x[,apply(y,2,min)<=0.05]
  #y = y[,apply(y,2,min)<=0.05]
  #x = x[apply(y,1,min)<=0.05,]
  #y = y[apply(y,1,min)<=0.05,]
  #y = y[,apply(x,2,max)>=0.2]
  #x = x[,apply(x,2,max)>=0.2]
  #y = y[apply(x,1,max)>=0.2,]
  #x = x[apply(x,1,max)>=0.2,]
  y[y<0.001] = "**"
  y[y>0.001&y<0.01] = "*"
  y[y>0.01&y<0.05] = "+"
  y[y>0.05] = ""
  
  p<-heatmap.2(x,col = colorRampPalette(c("#EF3F3A", "white", "#05ADAD"))(20), 
               #split = mtcars$cyl,
               key = TRUE, symkey = FALSE, density.info = "none", 
               trace = "none", cexRow = 0.5,Rowv = F,Colv = F,
               main = "Heatmap",cellnote = y,notecol = "black"#,行不聚类,Rowv = F列不聚类,Colv = FALSE,
  )
  return(p)
}


heat_map(cor_r_r,cor_r_p)
