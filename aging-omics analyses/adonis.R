Med = read.table('../Med.txt',sep = "\t",check.names = F,
                 stringsAsFactors = F,header = T,row.names = 1)
#Med = Med[,-c(15:18)]
BM = read.csv("../代谢组数据_new.txt",sep = "\t",check.names = F,
                stringsAsFactors = F,header = T,row.names = 1)
Med = Med[row.names(BM),]
data1 =matrix(rep(0,ncol(Med)*3),ncol = 3)
data1[,1] = colnames(Med)
colnames(data1) = c("name","R2","p.value")
data1 = data.frame(data1,check.names = F,stringsAsFactors = F)
library(vegan)
for(i in 1:ncol(Med)){
  a = Med[,i]
  b = BM[!is.na(a),]
  d = adonis(b~a)
  data1[i,2] = d$aov.tab[,5][1]
  data1[i,3] = d$aov.tab[,6][1]
}
#data1 = data1[-c(15:18),]
library(ggplot2)
data1[,2] = as.double(data1[,2])
data1 = data1[data1$p.value<0.05,]
data1 = data1[order(data1$R2,decreasing = T),]
data1$name = factor(data1$name,levels = rev(data1$name))
ggplot(data1,aes(x = name,y = R2))+geom_bar(stat = 'identity', position = 'dodge')+
  theme_classic()+coord_flip()
Med = Med[!is.na(apply(Med, 1, sum)),]
BM = BM[row.names(Med),]
Med = Med[,data1[,1]]
adonis(BM~.,data = Med)
