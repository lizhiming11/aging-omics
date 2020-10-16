perl split_fa.pl s 9 gene_catalog.fas.pep split
blastp -query split_1.fa -out split_1.bt -db KEGG.fa -evalue 1e-10 -outfmt 6 -num_threads 20
perl get_pep.length.pl gene_catalog.fas.pep gene_catalog.fas.pep.len&
filter_blast -i split_1.bt -o split_1.bt.f  --identity 30 --evalue 1e-10 --qfile gene_catalog.fas.pep.len --qper 70 --wins 1
less split_1.bt.f | perl -ne '@s=split /\s+/;print $_ unless $a eq $s[0];$a=$s[0];' > split_1.bt.f2
