wget https://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nt.gz
wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz
wget https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdmp.zip

perl get.node_gi.v3.accession.pl 2 nt.2 nodes.dmp nucl_gb.accession2taxid.gz
perl get.node_gi.v3.accession.pl 2157 nt.2157 nodes.dmp nucl_gb.accession2taxid.gz
perl get.node_gi.v3.accession.pl 10239 nt.10239 nodes.dmp nucl_gb.accession2taxid.gz
perl get.node_gi.v3.accession.pl 12884 nt.12884 nodes.dmp nucl_gb.accession2taxid.gz
perl get.node_gi.v3.accession.pl 1301 nt.1301 nodes.dmp nucl_gb.accession2taxid.gz
perl get.node_gi.v3.accession.pl 4751 nt.4751 nodes.dmp nucl_gb.accession2taxid.gz

cat nt.2 nt.2157 nt.10239 nt.12884 nt.1301 nt.4751 > NCBI-NT.fa
makeblastdb -in NCBI-NT.fa -dbtype nucl

perl split_fa.pl s 9 ../gene_catalog.fas split
blastn -word_size 16 -query split_1.fa -out split_1.bt -db NCBI-NT.fa -evalue 1e-10 -outfmt 6 -num_threads 20
perl get_length.pl gene_catalog.fas.pep gene_catalog.fas.pep.len
filter_blast -i split_1.bt -o split_1.bt.f --qfile gene_catalog.fas.pep.len --qper 70 --tops 5
perl get_species_anno.v2019.pl split_1.bt.f split_1.bt.f.tax 
