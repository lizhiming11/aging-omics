fq1 = $1
fq2 = $2
outfile = $3

megahit -1 $fq1 -2 $fq2 -o $outfile -t 20 --min-contig-len 500 --k-min 21 --k-max 81 --k-step 20
