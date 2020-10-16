2bwt-builder gene_catalog.fas && touch gene_catalog.fas.index
fasta_length -i gene_catalog.fas | awk '{print NR"\t"$0}'>  gene_catalog.fas.length

sample = $1
perl abundance.pl -a $sample_rmHost.1.fq.gz -b $sample_rmHost.2.fq.gz -d gene_catalog.fas.index -g  gene_catalog.fas.length -p ./abundance/$sample

profile_v1.0 -i skin_list -p gene_profile

perl genecatalog-profile2.pl -i gene_profile -o species.profile -l gene_catalog.fas.length -a NT.tax

perl genecatalog-profile2.pl -i gene_profile -o ko.profile -l gene_catalog.fas.length -a ko.ann

perl genecatalog-profile2.pl -i gene_profile -o card.profile -l gene_catalog.fas.length -a card.ann
