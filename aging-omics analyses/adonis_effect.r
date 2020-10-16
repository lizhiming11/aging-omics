corr_self <- function(x,y){
  name = x[,1]
  MGS1 = y[,name]
  corr_MGS_FM = corr.test(MGS1)
  a = corr_MGS_FM$r
  for(i in 1:nrow(a)){
    for(j in i:nrow(a)){
      a[j,i] = 0
    }
  }
  for(k in 1:nrow(x)){
    a = a[!a[k,]>0.8,!a[k,]>0.8]
    if(nrow(a)==k){
      break
    }
  }
  return(row.names(a))
}

calculta_R <- function(x,y){
  x <- x[order(x[,2],decreasing = T),]
  x <- x[x[,3]<=0.05,]
  y_value <- y[,corr_self(x,y)]
  y_BM_adonis <- adonis(BM~.,data = y_value)
  y_BM_adonis
}

adonis_self <- function(x,y){
  data1 = matrix(rep(0,ncol(x)*3),ncol = 3)
  data1[,1] = colnames(x)
  colnames(data1) = c("name","R2","P")
  for(i in 1:ncol(x)){
    a = adonis(y~x[,i])
    data1[i,2] = a$aov.tab$R2[1]
    data1[i,3] = a$aov.tab$`Pr(>F)`[1]
  }
  return(data1)
}
MGS = read.csv("../Med.txt",sep ="\t",
                 row.names = 1,header = T,check.names = F,stringsAsFactors = F)
#MGS = data.frame(t(MGS),check.names = F,stringsAsFactors = F)
MGS = MGS[,c(19:31)]
BM =read.csv("../代谢组数据_new.txt",sep = "\t",check.names = F,
               stringsAsFactors = F,header = T,row.names = 1)
mapping = read.table("../mapping.txt",sep = "\t",check.names = F,
                     stringsAsFactors = F,header = T,row.names = 1)
type = "elderly"
mapping = mapping[mapping$Group==type,]
mapping = mapping[row.names(mapping)%in%row.names(BM),]
BM = BM[row.names(mapping),]
MGS = MGS[row.names(mapping),]
#MGS = MGS[-22,]
#BM = BM[-22,]
MGS = MGS[,apply(MGS, 2, sum)!=0]
library(vegan)
library(psych)
adonis_data = adonis_self(MGS,BM)
#adonis_data = adonis_data[adonis_data[,3]<0.05,]
adonis_data = data.frame(adonis_data,check.names = F,stringsAsFactors = F)
adonis_value = adonis(BM~.,data = MGS[,adonis_data[adonis_data$P<0.02,1]])
#adonis_value = calculta_R(adonis_data,MGS)
adj_adonis_value = RsquareAdj(1-adonis_value[[1]][5][,1][length(adonis_value[[1]][5][,1])-1],
                              nrow(BM),length(adonis_value[[1]][5][,1])-2)
