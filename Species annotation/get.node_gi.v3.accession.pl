use strict;
use warnings;

#该脚本用于从nt库中挑选出关注的菌名下的所有序列，可用于建库比对。
#node为物种taxonomyID，node_demp为从ncbi下载的NT库中的taxonomyID，
#gi_taxid为从ncbi下载的nucl_gb.accession2taxid.gz（包含基因序列和物种ID的对应编号），database为nt库序列。

unless (@ARGV == 5){
	print "perl $0 <node> <output_fa> <node_dmp> <gi_taxid> <database>\n";
	exit 0;
}

my $node = shift;
my $out_fa = shift;
my $node_dmp = shift;
my $gi_taxid = shift;
my $nt = shift;

my %h_node_dmp = &get_node_dmp();
print "get node dmp done!\n";
my %h_gi = &get_gi();
print "get gi done!\n";
&get_fa();
print "get fa done!\n";

sub get_fa{
	my $key = 0;

	open NT, "gzip -dc $nt |" or die "$!";
	open OUT, ">$out_fa" or die "$!";
	while (my $line = <NT>){
		chomp $line;
		if ($line =~ /^>/){
			$key = 0;
			#######################################
			my @tt = split /\001/, $line;
			my @aa = ();
			foreach (@tt) {
				s/^>//;
				s/\s+.*$//g;
				if (exists $h_gi{$_}) { $key = 1; push @aa, $_; }
			}
			if(@aa==1){ print OUT ">$aa[0]\n";
			}elsif(@aa>1){
				my $aa = shift @aa;
				print OUT ">$aa ".($#aa+2)." ".(join " ",@aa)."\n";
			}
			#######################################
		}else{
			print OUT "$line\n" if $key == 1; 
		}
	}
	close OUT;
	close NT;
}

sub get_gi{
	my %hash = ();
	open IN, "gzip -dc $gi_taxid |" or die "$!";
	<IN>;
	while(<IN>){
		chomp;
		my @s = split /\s+/;
		$hash{$s[1]} = 1 if exists $h_node_dmp{$s[2]};
	}
	close IN;
	return %hash;
}

sub get_node_dmp {
	open NODE_DMP, $node_dmp or die "$!";
	my %hash = ();
	while (my $l_node = <NODE_DMP>){
		chomp $l_node;
		my ($tax_id, $parent_tax_id) = split /\s+\|\s+/, $l_node;
		push (@{$hash{$parent_tax_id}}, $tax_id);
	}
	close NODE_DMP;
	my %h_tree = ();
	my @array = @{$hash{$node}};
	my @sub_array = @{$hash{$node}};
	my @tem_array = ();
	while (1){
		foreach my $branch (@sub_array){
			if (exists $hash{$branch}){
				push (@tem_array, @{$hash{$branch}});
			}
		}
		@sub_array = @tem_array;
		push (@array, @sub_array);
		last if (@sub_array == 0);
		@tem_array = ();
	}
	
	foreach my $sub_node (@array){
		$h_tree{$sub_node} = 1; #########
		#print "$sub_node\t$h_tree{$sub_node}\n"if ($h_tree{$sub_node} > 1);
		#print "$sub_node\t3\n";
	}
	return %h_tree;
}
