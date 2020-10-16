contig = $1
filter_contig = $2
prediction = $3

select_fasta -i $contig -c 500 -o $filter_contig.fas
gmhmmp -f G -A $prediction.faa -D $prediction.ffn -p 1 -g 11 -m MetaGeneMark_v1.mod -o $prediction.gff .$filter_contig.fas
gzip $filter_contig.fas
gzip $prediction.faa
gzip $prediction.gff
