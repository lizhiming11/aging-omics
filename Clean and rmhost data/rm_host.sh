fq1 = $1
fq2 = $2
hg19 = $3
outfile = $4

soap -a $fq1 -b $2 -D $hg19 -o $outfile.pe -2 $outfile.se -v 8 -r 1 -l 35 -M 4 -p 10 2> $outfile.log                                  
sed 's/\/[1,2].*//' $4 $5 |sort |uniq >$outfile.list
zcat $fq1 |awk 'BEGIN{while (getline a < "'$outfile.list'")arr[a] = 1}{getline seq;getline plus;getline qual;name = $0}{sub(/\/.*/,"",$0);sub(/@/,"",$0)}{if ($0 in arr == 0) print name "\n" seq "\n" plus "\n" qual }' >$outfile.1.fq
zcat $fq2 |awk 'BEGIN{while (getline a < "'$outfile.list'")arr[a] = 1}{getline seq;getline plus;getline qual;name = $0}{sub(/\/.*/,"",$0);sub(/@/,"",$0)}{if ($0 in arr == 0) print name "\n" seq "\n" plus "\n" qual }' >$outfile.2.fq
gzip -f $outfile.1.fq $outfile.2.fq 
rm $outfile.pe $outfile.se $outfile.list
