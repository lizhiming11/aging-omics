suppressPackageStartupMessages(library(randomForest))
suppressPackageStartupMessages(library(argparse))
suppressPackageStartupMessages(library(parallel))


Species = read.table("mgs.profile",row.names = 1,header = T,check.names = F,stringsAsFactors = F,sep = "\t")
row.names(Species) = gsub("GS","",row.names(Species))
Species = data.frame(t(Species),check.names = F,stringsAsFactors = F)
BM = read.table("BM.txt",sep = "\t",header = T,row.names = 1,check.names = F,stringsAsFactors = F)
Species = Species[row.names(Species)%in%row.names(BM),]
Species_list= read.table("Phenol_import.txt",sep= "\t",check.names = F,
                         stringsAsFactors = F,header = T,row.names = 1)
Species = Species[,Species_list[,1]]
BM = BM[row.names(Species),]
a1_name = colnames(BM)[3]
BM = BM[,3]
Species = Species[!is.na(BM),]
BM = BM[!is.na(BM)]
names(Species) <- make.names(names(Species))
fit <- randomForest(BM~ ., data=Species, importance=TRUE, proximity=TRUE, ntree=1000)
imp <- importance(fit,type = 1)
impvar <- imp[order(imp[,1],decreasing = TRUE),]
Species = Species[,row.names(impvar)]
result = matrix(rep(0,250),nrow = 50,ncol = 5)
colnames(result) = c("RMSE","DRMSE",'COR','Q2',"name")
result[1,5] = colnames(Species)[1]
fun_q <- function(x){
  rmse = sqrt(mean((as.double(BM)-as.double(x))^2))
  drmse = rmse/(max(as.double(BM))-min(as.double(x)))
  Q2 = 1-sum((BM-as.double(x))**2)/sum((BM-mean(as.double(x)))**2)
  a = cor(as.double(BM),as.double(x))
  b = rmse 
  m = drmse
  d = Q2
  k = c(b,m,a,d)
  return(k)
}
random_test = function(x){
  fit <- randomForest(BM~ ., data=x, importance=TRUE, 
                      proximity=TRUE, ntree=1000)
  a <- as.double(fit$predicted)
  return(a)
}
leave_one = function(x){
  a = c()
  for(i in 1:nrow(x)){
    traindata = x[-i,]
    train_BM = BM[-i]
    testdata = x[i,]
    test_BM = BM[-i]
    fit <- randomForest(train_BM~ ., data=traindata, importance=TRUE, 
                        proximity=TRUE, ntree=1000)
    preds <- predict(fit, testdata)
    m <- as.double(preds)
    a = c(a,m)
  }
  return(a)
}
calculate_q = function(x){
  name1 = colnames(Species2)[x]
  Species3 = cbind(Species1,Species2[,x])
  colnames(Species3)[ncol(Species3)] = name1
  n = random_test(Species3)
  Q_value = fun_q(n)
  return(c(name1,Q_value))
}
set.seed(123)
Species1 = data.frame(Species[,1])
colnames(Species1) = colnames(Species)[1]
for(j in 1:(ncol(Species)-1)){
  Species2 = Species[,!colnames(Species)%in%colnames(Species1)]
  k = 1:ncol(Species2)
  cl <- makeCluster(as.double(tnum)) #CPU
  clusterExport(cl,"Species2")
  clusterExport(cl,"Species1")
  clusterExport(cl,"random_test")
  clusterExport(cl,"randomForest")
  clusterExport(cl,"BM")
  clusterExport(cl,"fun_q")
  clusterExport(cl,"leave_one")
  results <- parLapply(cl,k,calculate_q) 
  res.df <- do.call('rbind',results) 
  stopCluster(cl) 
  m_result = res.df[which.max(res.df[,4]),]
  name1 = m_result[1]
  result[(j+1),5] = name1
  result[(j+1),1:4] = m_result[2:5]
  Species1 = cbind(Species1,Species[,name1])
  colnames(Species1)[ncol(Species1)] = name1
  if(result[50,5]!=0){
    break
  }
  print(j)
}

write.table(result,paste(a1_name,"result.txt",sep = "_"),quote = F,sep = "\t",row.names = F)

result = data.frame(result,stringsAsFactors = F)
result$name = as.character(result$name)

b = result[which.max(result[,4]),]
name3 = result[1:which.max(result[,4]),5]
data_new = Species[,name3]
random_value = leave_one(data_new)
random_q = fun_q(random_value)

name = b[,5]
row.names(b) = a1
b[1,5] = paste(colnames(data_new),collapse =",")
b[1,1:4] = random_q
write.table(b,paste(a1_name,"result_filter.txt",sep = "_"),quote = F,sep = "\t")

fit1 <- randomForest(BM~ ., data=data_new, importance=TRUE, 
                     proximity=TRUE, ntree=1000)
imp <- importance(fit1)
impvar <- imp[order(imp[,1],decreasing = TRUE),]
fit1$name = row.names(impvar)
write.table(impvar,paste(a1_name,"import.txt",sep = "_"),quote = F,sep = "\t")
save(fit1,file = paste(a1_name,"_module.RData",sep = ""))
