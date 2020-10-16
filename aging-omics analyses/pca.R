#!/usr/bin/env Rscript

# -------------- NOTE: ---------------
# The last column should be the class.
# ------------------------------------

suppressPackageStartupMessages(library(argparse))
suppressPackageStartupMessages(library(ade4))
#suppressPackageStartupMessages(library(fpc))
suppressPackageStartupMessages(library(ggrepel))
suppressPackageStartupMessages(library(RColorBrewer))
suppressPackageStartupMessages(library(grid))
suppressPackageStartupMessages(library(gridExtra))
suppressPackageStartupMessages(library(vegan))
#library(ggthemes)

parser <- ArgumentParser()

parser$add_argument("-i", help = "input otufile or Kegg with the descriptors")
parser$add_argument("-t", help = "input file with the classified")
parser$add_argument("-o", help = "input output file")
parser$add_argument("-l", help = "input Axis1-Axis10,default Axis1",default='Axis1')
parser$add_argument("-r", help = "input Axis1-Axis10,default Axis2",default="Axis2")
parser$add_argument("-f", help = "image format, png|pdf, default png",default='png')
parser$add_argument("-w", help = "image width, units inches, default 10",default=10)
parser$add_argument("-e", help = "image height, units inches, default 7",default=7)
parser$add_argument("-cw", help = "The size of the circle",default=3)
parser$add_argument("-il", help = "The length of the line",default=0.3)
args <- parser$parse_args()

infile <- file.path(args$i)
inclass <- file.path(args$t)
inlift <- file.path(args$l)
inout <- file.path(args$o)
inright <- file.path(args$r)
informat <- file.path(args$f)
inwidth <- file.path(args$w)
inheight <- file.path(args$e)
incw <- file.path(args$cw)
inlength <- file.path(args$il)

cat("\nUsing the following setting:\n")
cat("------------------------------------\n")
cat("Input otufile or Kegg: ", infile, "\n")
cat("Input classified: ", inclass, "\n")
cat("input axis1: ", inlift, "\n")
cat("input axis2: ", inright, "\n")
cat("input mage format: ", informat, "\n")
cat("input width: ", inwidth, "\n")
cat("input height: ", inheight, "\n")
cat("input output: ", inout, "\n")
cat("input incw:",incw,"\n")
cat("------------------------------------\n")


species<-function(ii){
  ii<-as.character(ii)
  ii[intersect(grep('.*[|,.;]g__.*[|,.;]s__..*',ii),grep('[|,.;]s__$',ii,invert=T))]<-as.character(lapply(ii[intersect(grep('.*[|,.;]g__.*[|,.;]s__..*',ii),grep('[|,.;]s__$',ii,invert=T))],function(x){gsub('.*[|,.;]s','s',x)}))
  ii[intersect(grep('.*[|,.;]f__.*[|,.;]g__..*',ii),grep('g__[|,.;]s__',ii,invert=T))]<-as.character(lapply(ii[intersect(grep('.*[|,.;]f__.*[|,.;]g__..*',ii),grep('g__[|,.;]s__',ii,invert=T))],function(x){gsub('.*[|,.;]g','g',x)}))
  ii[intersect(grep('.*[|,.;]o__.*[|,.;]f__..*',ii),grep('f__[|,.;]g__',ii,invert=T))]<-as.character(lapply(ii[intersect(grep('.*[|,.;]o__.*[|,.;]f__..*',ii),grep('f__[|,.;]g__',ii,invert=T))],function(x){gsub('.*[|,.;]f','f',x)}))
  ii[intersect(grep('.*[|,.;]c__.*[|,.;]o__..*',ii),grep('o__[|,.;]f__',ii,invert=T))]<-as.character(lapply(ii[intersect(grep('.*[|,.;]c__.*[|,.;]o__..*',ii),grep('o__[|,.;]f__',ii,invert=T))],function(x){gsub('.*[|,.;]o','o',x)}))
  ii[intersect(grep('.*[|,.;]p__.*[|,.;]c__..*',ii),grep('p__[|,.;]c__',ii,invert=T))]<-as.character(lapply(ii[intersect(grep('.*[|,.;]p__.*[|,.;]c__..*',ii),grep('p__[|,.;]c__',ii,invert=T))],function(x){gsub('.*[|,.;]c','c',x)}))
  ii[intersect(grep('k__.*[|,.;]p__..*',ii),grep('k__[|,.;]p__',ii,invert=T))]<-as.character(lapply(ii[intersect(grep('k__.*[|,.;]p__..*',ii),grep('k__[|,.;]p__',ii,invert=T))],function(x){gsub('.*[|,.;]p','p',x)}))
  return(ii)
}


infile = "../代谢组数据_new.txt"
inclass = "../mapping.txt"
incw = 2
inlength = 3
inlift = "Axis1"
inright = "Axis2"

dat <- read.csv(infile, head=T, sep="\t",row.names = 1,check.names = F,
                  stringsAsFactors = F)#,comment.char = "",skip = 1)
#row.names(dat) = species(row.names(dat))
#dat = read.table("bdiv_even19238_L7.txt", head=T, sep="	",row.names = 1,check.names = F,
  #               stringsAsFactors = F,comment.char = "",skip = 1)
#data1 = read.table("mapping_A_B",header = T,stringsAsFactors = F,
  #                 comment.char = "",check.names = F)
data1 = read.table(inclass,sep = "\t",header = T,stringsAsFactors = F,check.names=F,row.names = 1)#,comment.char = "",sep ="\t")
#dat = dat[,colnames(dat)%in%as.character(data1[,1])]
#data1 = data1[as.character(data1[,1])%in%colnames(dat),]
#dat <- dat[rowSums(dat)!=0,]
data1 = data1[row.names(dat),]
#dat = dat[,data1[,1]]
data = dat
data1 =data1[,c(-2)]
data1 =data1[,c(1,3,2)]
#data <- sweep(dat, 2, apply(dat,2,sum), "/")
colnames(data1)[2] ="Group"

data <- t(sqrt(data))
data.dudi <- dudi.pca(data, center=TRUE, scale=F, scan=F, nf=10)
data2 <- data.dudi$li
incw = as.double(incw)
inlength = as.double(inlength)
classified_c = as.character(unique(data1[,2]))
#data3 = merge(data2,data1,by = "row.names")
#row.names(data3) = data3[,1]
#data3 = data3[,-1]

adonis1<-adonis(dat ~ data1$Age.x,permutations = 999,method = "bray")

phenotype <- data1[,2]
type = 
f = classified_c
Type <- factor(phenotype,levels=f)
m = data.dudi$li
n = data.dudi$c1

lift_data = m[as.character(inlift)]
row.names(lift_data) = gsub(pattern = "[.]",replacement = "-",row.names(lift_data))
right_data = m[as.character(inright)]
row.names(right_data) = gsub(pattern = "[.]",replacement = "-",row.names(right_data))
data.dudi$li = cbind(lift_data,right_data)
num1 = substring(as.character(inlift),5,6)
num2 = substring(as.character(inright),5,6)
num1_data = n[paste("CS",num1,sep = '')]
num2_data = n[paste("CS",num2,sep = '')]
data.dudi$c1 = cbind(num1_data,num2_data)

right_data_box= cbind(data1[,2],right_data)
colnames(right_data_box)[1] = "Group" 
lift_data_box = cbind(data1[,2],lift_data)
colnames(lift_data_box)[1] = "Group" 

#png(paste(infile,"PC",num1,"-","PC",num2,".png",sep = "_"), width = 1000, height = 768, res = 100)
#png("2017.Jun11.Throat.Stool.16S.otu.Tonsil.prof.Disease.PCA.png", width = 768, height = 768, res = 72)
x1 <- min(data.dudi$li[,1]) - 0.3
y1 <- min(data.dudi$li[,2]) - 0.3
x2 <- max(data.dudi$li[,1]) + 0.3
y2 <- max(data.dudi$li[,2]) + 0.3
bb <- head(data.dudi$c1[order(sqrt((data.dudi$c1[,1])^2+(data.dudi$c1[,2])^2),decreasing=T),],n=7L)[1:7,]
rownames(bb) <- gsub("^X", "", rownames(bb))
rownames(bb) <- gsub("\\S+o__", "o__", rownames(bb))
cutoff <- (x2-0.3) / abs(bb[1,1]) * inlength
d2 <- data.frame(X=bb[1:dim(bb)[1],1]*cutoff, Y=bb[1:dim(bb)[1],2]*cutoff, LAB=rownames(bb)[1:dim(bb)[1]])
#d2[[3]]<- gsub('.*f__','f__',as.character(d2[[3]]))
d2[[3]] <- gsub('.*o__','o__',as.character(d2[[3]]))
d2[[3]] <- gsub('.*c__','c__',as.character(d2[[3]]))
d2[[3]] <- gsub('.*p__','p__',as.character(d2[[3]]))

d <- data.dudi$li
eig <- ( data.dudi$eig / sum( data.dudi$eig ) )

#track <- read.table("2.beta_div/plots/pca/2017.Jun11.Throat.Stool.16S.otu.Tonsil.prof.track", head=T, sep="	")
#points <- read.table("2.beta_div/plots/pca/2017.Jun11.Throat.Stool.16S.otu.Tonsil.prof.points", head=T, sep="	")

ggdata <- as.data.frame(d)

p<-ggplot(ggdata) +
  xlab("") +
  ylab("") +
  geom_vline(xintercept = 0) +
  geom_hline(yintercept = 0) +
#p+geom_point(aes(x=d[,1], y=d[,2], color=Type), size=2, shape=19) +
  geom_point(aes(x=d[,1], y=d[,2], color=Type,shape = data1[,3]), size=3) +
  stat_ellipse(aes(x=d[,1], y=d[,2], fill=Type), size=1, geom="polygon", level=0.8, alpha=0.3) +
  geom_text_repel(data=d2, aes(x=X, y=Y, label=LAB),
            family="Helvetica", fontface="italic", size=3, check_overlap=TRUE) +
  geom_segment(data=d2, aes(x=0, y=0, xend=X, yend=Y),
               arrow = arrow(length = unit(0.3, "cm")), size=0.8, alpha=0.5)+
  #geom_segment(data=track, aes(x=x1, y=y1, xend=x2, yend=y2),
  #             arrow = arrow(length = unit(0.4, "cm")), size=1, alpha=0.8) +
  #geom_point(data=points, aes(x=x1, y=y1, color=factor(Type)),
  #           size=6, shape=19, alpha=0.7) +
  #geom_text_repel(data=ggdata, aes(x=d[,1], y=d[,2], label=row.names(ggdata)),
  #          family="Helvetica", size=3, check_overlap=TRUE) +
  scale_color_manual(values=brewer.pal(9,"Set1"))+
    scale_fill_manual(values=brewer.pal(9,"Set1"))+
  guides(color=guide_legend(colnames(data1)[2]),
         fill=guide_legend(colnames(data1)[2]),
         shape=guide_legend(colnames(data1)[2]) ) +
  theme_classic()+
  theme(panel.grid = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        legend.position=c(0.9,0.9),
        text=element_text(
          family="Helvetica",
          face="bold",
          colour="black",
          size=9
        ),
        legend.title=element_text(
          family="Helvetica",
          colour="black",
          size=9
        ),
        legend.text=element_text(
          family="Helvetica",
          colour="black",
          size=16
        )
  )+xlim(min(d[,1], 0)*incw, max(d[,1])*incw)+ylim(min(d[,2], 0)*incw, max(d[,2])*incw)
#xlim(min(d[,1], 0)*3, max(d[,1])*3)+ylim(min(d[,2], 0)*3, max(d[,2])*3)
p <- ggplotGrob(p)
right_data_box$Group = factor(right_data_box$Group, levels=f)
d <- ggplot(right_data_box)+geom_boxplot(aes(x = Group,y = right_data_box[,2],fill = Group),width = 0.5)+
  theme_bw()+theme(panel.grid =element_blank())+
  #scale_fill_wsj("colors6", "Group")
  scale_fill_manual(values=brewer.pal(9,"Set1"),breaks =f)+
  guides(fill=FALSE)+theme(axis.text.x = element_blank())+
  theme(axis.ticks = element_blank(),
        text=element_text(
          family="Helvetica",
          face="bold",
          colour="black",
          size=12
        ))+
  ylim(min(right_data_box[,2], 0)*incw, max(right_data_box[,2])*incw)+
 # ylim(min(right_data_box[,2], 0)*3, max(right_data_box[,2])*3)+
  xlab("")+ylab(paste("PC",num2," (",round(eig[as.numeric(num2)]*100,2),"%)",sep=""))
lift_data_box$Group = factor(lift_data_box$Group, levels=f)
b<- ggplot(lift_data_box)+geom_boxplot(aes(x = Group,y = lift_data_box[,2],fill = Group),width = 0.5)+
  theme_bw()+theme(panel.grid =element_blank())+coord_flip()+
  guides(fill=FALSE)+theme(axis.text.y = element_blank())+
  theme(axis.ticks = element_blank(),
        text=element_text(
          family="Helvetica",
          face="bold",
          colour="black",
          size=12
        ))+
  scale_fill_manual(values=brewer.pal(9,"Set1"))+
  ylim(min(lift_data_box[,2], 0)*incw, max(lift_data_box[,2])*incw)+
  xlab("")+ylab(paste("PC",num1," (",round(eig[as.numeric(num1)]*100,2),"%)",sep=""))
a<-ggplot()+theme_bw()+theme(panel.border = element_blank(),panel.grid =element_blank(),
  axis.text = element_blank(),axis.title = element_blank(),
  axis.ticks = element_blank())+
  annotate("text", x=1, y=40, label=paste("P.value =",round(adonis1[[1]][6][[1]][1],4),'\n',
                                          "R2      =",round(adonis1[[1]][5][[1]][1],4)), size=3.5)

a <- ggplotGrob(a)
d <- ggplotGrob(d)
b <- ggplotGrob(b)

#if(informat=="pdf"){
#    pdf(paste(inout,"pdf",sep = "."),width = as.double(inwidth), height = as.double(inheight))
#}else{
#    png(paste(inout,"png",sep = "."),width = as.double(inwidth), height = as.double(inheight), units = "in", res = 100)
#}
grid.arrange(d,p,a,b,ncol=2,widths=c(1,4),heights = c(4,1))

#dev.off()

