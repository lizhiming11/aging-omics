cat *.ffn > gene_catalog.cds
perl cd-hit-para-sge.pl -i gene_catalog.cds -o gene_catalog.fas -G 0 -n 10 -M 90000 -r 0 -T 0 -c 0.95 -aS 0.90 --Q 10 --S 20 --P cd-hit-est --T SGE
