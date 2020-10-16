use warnings;
use strict;

my $usage = "usage: perl $0 [type] [file num] [old_file.fa] [new_file_prefix]
      type
        n\t\tfile number
        s\t\tfile size\n";
die $usage if (@ARGV != 4 or ($ARGV[0] ne 'n' and $ARGV[0] ne 's'));

my ($num, $len) = (0, 0);
if ($ARGV[2] =~ /\.gz$/) { open IN, "gzip -dc $ARGV[2] |" or die $!;
} else { open IN, $ARGV[2] or die $!;
}
while (<IN>) {
    chomp;
    if (/^>/) { $num ++;
    } else { $len += length $_;
    }
}
close IN;

my ($file_num, $file_len) = (0, 0);
if ($ARGV[0] eq 'n') {
    $file_num = sprintf ("%1.0f", $num / $ARGV[1]);
	
	if ($ARGV[2] =~ /\.gz$/) { open IN, "gzip -dc $ARGV[2] |" or die $!;
	} else { open IN, $ARGV[2] or die $!;
	}
    my $flag = 1;
    my $count = -1;
    open OUT, ">$ARGV[3]\_$flag.fa" or die $!;
    while (<IN>) {
	chomp;
	if (/^>/) {
	    $count ++;
	    if ($count > $file_num and $flag < $ARGV[1]) {
		close OUT;
		$flag ++;
		open OUT, ">$ARGV[3]\_$flag.fa" or die $!;
		$count = 0;
	    }
	}
	print OUT "$_\n";
    }
    close IN;
    close OUT;
} else {
    $file_len = sprintf ("%1.0f", $len / $ARGV[1]);
	
	if ($ARGV[2] =~ /\.gz$/) { open IN, "gzip -dc $ARGV[2] |" or die $!;
	} else { open IN, $ARGV[2] or die $!;
	}
    my $flag = 1;
    my $size = 0;
    my $seq = '';
    my $slen = 0;
    open OUT, ">$ARGV[3]\_$flag.fa" or die $!;
    while (<IN>) {
	chomp;
	if (/^>/) {
	    if ($seq ne '') {
		print OUT "$seq";
		if ($slen > $file_len and $flag < $ARGV[1]) {
		    close OUT;
		    $flag ++;
		    open OUT, ">$ARGV[3]\_$flag.fa" or die $!;
		    $slen = 0;
		}
	    }
	    $seq = "$_\n";
	} else {
	    $seq .= "$_\n";
	    $slen += length $_;
	}
    }
    print OUT "$seq";
    close OUT;
    close IN;
}

