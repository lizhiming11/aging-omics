#!/share/apps/perl5/bin/perl
use strict;
use Getopt::Std;
use FindBin;
use PerlIO::gzip;

#===============================================================================
my $Version = "2017.Dec27-17.49";
my $Modify  = "modify default values & allow repeat for soap alignment";
my $Contact = "ZHOU Yuanjie (ZHOU YJ), libranjie\@gmail.com";

#===============================================================================
sub usage {
  my ($reason) = @_;
  print STDERR "
  ==============================================================================
  $reason
  ==============================================================================
  " if ( defined $reason );
  print STDERR "
  Last modify: $Version
  Modify: $Modify
  Contact: $Contact
  Usage:
  \$perl $0 [options]
  -a : read1 file, required
  -b : read2 file, optional
  -c : single read file, optional
  -d : geneset database, required
  -g : geneset id and length information, required
  -m : match mode, default 4
  -s : seed length, default 35
  -r : repeat hit, default 1
  -n : minimal insert size, default 400
  -x : maximal insert size, default 600
  -v : maximum number of mismatches, default 15
  -i : identity, default 0.90
  -t : number of processors, default 14
  -f : simple soap result, default Y (Y/N)
  -p : output prefix, required
  -h : show the help message
  \n";
  exit;
}

#===============================================================================
our ( $opt_a, $opt_b, $opt_c, $opt_d, $opt_g, $opt_m, $opt_s, $opt_r );
our ( $opt_n, $opt_x, $opt_v, $opt_i, $opt_t, $opt_f, $opt_p, $opt_h );

#===============================================================================
&usage if ( 0 == @ARGV );
&usage unless ( getopts('a:b:c:d:g:m:s:r:n:x:v:i:t:f:p:h') );
&usage if $opt_h;
unless ( 0 == @ARGV ) {
  &usage("with undefined options: @ARGV");
}
&usage unless $opt_a && $opt_d && $opt_g && $opt_p;
$opt_m = 4    unless $opt_m;
$opt_s = 35   unless $opt_s;
$opt_r = 1    unless $opt_r;
$opt_n = 400  unless $opt_n;
$opt_x = 600  unless $opt_x;
$opt_v = 15   unless $opt_v;
$opt_i = 0.90 unless $opt_i;
$opt_t = 14   unless $opt_t;
$opt_f = "Y"  unless $opt_f;

#===============================================================================
my ( %readsnum, %length, @tmp, @name, @id, $i, %abundance, $total_abundance );
my ( $soap_path, $shell, @database, $database, $paired, $single,
  $single_single );
$soap_path = "$FindBin::Bin/../wgs/soap2.22";
@database  = split /:/, $opt_d;
$database  = join " -D ", @database;

#===============================================================================
if ($opt_b) {
  $shell = "$soap_path -a $opt_a -b $opt_b -D $database -M $opt_m -p $opt_t ";
  $shell .= "-r $opt_r -m $opt_n -x $opt_x -l $opt_s -v $opt_v -c $opt_i ";
  if ( $opt_f eq "Y" ) {
    $shell .= "-S ";
  }
  $shell .= "-o $opt_p.soap.pe -2 $opt_p.soap.se 2>$opt_p.soap.log";
  if ( system($shell) ) {
    print STDERR "reads align database error\n";
    exit(1);
  }
  if ($opt_c) {
    $shell = "$soap_path -a $opt_a -D $database -M $opt_m -p $opt_t ";
    $shell .= "-r $opt_r -l $opt_s -v $opt_v -c $opt_i ";
    if ( $opt_f eq "Y" ) {
      $shell .= "-S ";
    }
    $shell .= "-o $opt_p.soap.single 2> $opt_p.soap.single.log";
    if ( system($shell) ) {
      print STDERR "single read align database error\n";
      exit(1);
    }
  }
}
else {
  $shell = $shell = "$soap_path -a $opt_a -D $database -M $opt_m -p $opt_t ";
  $shell .= "-r $opt_r -l $opt_s -v $opt_v -c $opt_i ";
  if ( $opt_f eq "Y" ) {
    $shell .= "-S ";
  }
  $shell .= "-o $opt_p.soap 2> $opt_p.soap.log";
  if ( system($shell) ) {
    print STDERR "single read align database error\n";
    exit(1);
  }
}

#===============================================================================
open F, "<:gzip(autopop)", "$opt_g" or die "can't open file $opt_g $!\n";
while (<F>) {
  chomp;
  @tmp = split;
  $length{ $tmp[1] } = $tmp[2];
  push @id,   $tmp[0];
  push @name, $tmp[1];
}
close F;

#===============================================================================
open O, ">$opt_p.stat_out"
  or die "can't open file $opt_p.stat_out $!\n";
print O "Paired\tSingle\tSingle_Single\n";
if ($opt_b) {
  &get_abundance_pe("$opt_p.soap.pe");
  &get_abundance_se("$opt_p.soap.se");
  &stat_pair_log("$opt_p.soap.log");
  if ($opt_c) {
    &get_abundance_single("$opt_p.soap.single");
    &stat_single_log("$opt_p.soap.single.log");
    print O "$paired\t$single\t$single_single\n";
  }
  else {
    print O "$paired\t$single\t0\n";
  }
}
else {
  &get_abundance_single("$opt_p.soap");
  &stat_single_log("$opt_p.soap.log");
  print O "0\t$single_single\t0\n";
}
close O;

#===============================================================================
$total_abundance = 0;
for ( $i = 0 ; $i < @name ; $i++ ) {
  $readsnum{ $name[$i] } = 0 unless ( defined $readsnum{ $name[$i] } );
  $abundance{ $name[$i] } = $readsnum{ $name[$i] } / $length{ $name[$i] };
  $total_abundance += $abundance{ $name[$i] };
}
$total_abundance = 1 if $total_abundance == 0;
open O, ">:gzip", "$opt_p.gz"
  or die "can't open file $opt_p.gz $!\n";
for ( $i = 0 ; $i < @id ; $i++ ) {
  print O "$id[$i]\t$readsnum{$name[$i]}\t$abundance{$name[$i]}\t",
    $abundance{ $name[$i] } / $total_abundance, "\n";
}
close O;
#system("rm -f $opt_p.soap $opt_p.soap.single $opt_p.soap.pe $opt_p.soap.se");

#===============================================================================
sub get_abundance_pe {
  my $file = shift;
  open I, $file or die "can't open file $file $!\n";
  my @temp;
  while (<I>) {
    chomp;
    @temp = split;

    #next unless ( 1 == $temp[3] );
    $readsnum{ $temp[7] } += 0.5;
  }
  close I;
}

#===============================================================================
sub get_abundance_se {
  my $file = shift;
  my ( @temp, %past );
  open I, $file or die "can't open file $file $!\n";
  while (<I>) {
    chomp;
    @temp = split;

    #next unless ( $temp[3] == 1 );
    if ( $temp[6] eq "+" ) {
      if ( ( $length{ $temp[7] } - $temp[8] ) < $opt_x ) {
        $temp[0] =~ /^(\S+)\/[12]/;
        $past{ $temp[7] }{$1} = 1;
      }
    }
    elsif ( $temp[6] eq '-' ) {
      if ( ( $temp[8] ) < $opt_x - $temp[5] ) {
        $temp[0] =~ /^(\S+)\/[12]/;
        $past{ $temp[7] }{$1} = 1;
      }
    }
  }
  close I;
  foreach my $key ( keys %past ) {
    foreach my $read ( keys %{ $past{$key} } ) {
      if ( $past{$key}{$read} ) {
        ++$readsnum{$key};
      }
    }
  }
}

#===============================================================================
sub get_abundance_single {
  my $file = shift;
  my @temp;
  open I, $file or die "can't open file $file $!\n";
  while (<I>) {
    chomp;
    @temp = split;
    next unless ( $temp[3] == 1 );
    $temp[0] =~ /^(\S+)\/[12]/;
    $readsnum{ $temp[7] }++;
  }
}

#===============================================================================
sub stat_pair_log {
  my $file = shift;
  open I, $file or die "can't open file $file $!\n";
  while (<I>) {
    chomp;
    if (/^Paired:\s+(\d+)/) {
      $paired = $1;
    }
    elsif (/^Singled:\s+(\d+)/) {
      $single = $1;
    }
  }
  close I;
}

#===============================================================================
sub stat_single_log {
  my $file = shift;
  open I, $file or die "can't open file $file $!\n";
  while (<I>) {
    chomp;
    if (/^Alignment:\s+(\d+)/) {
      $single_single = $1;
      last;
    }
  }
  close I;
}
