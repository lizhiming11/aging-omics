#!/share/apps/perl5/bin/perl
use strict;
use warnings;
use utf8;
use Getopt::Std;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

#===============================================================================
my $Version = "2017.Dec1-19.11";
my $Contact = "ZHOU Yuanjie (ZHOU YJ), libranjie\@gmail.com";

#===============================================================================
our ( $opt_i, $opt_o, $opt_l, $opt_a, $opt_h );

#===============================================================================
&usage if ( 0 == @ARGV );
&usage unless ( getopts('i:o:l:a:h') );
&usage if ( defined $opt_h );
unless ( 0 == @ARGV ) {
  &usage("with undefined options: @ARGV");
}
&usage("lack input genecatalog profile with: -i") unless ( defined $opt_i );
&usage("lack output KO profile with: -o")         unless ( defined $opt_o );
&usage("lack input genecatalog length with: -l")  unless ( defined $opt_l );
&usage("lack input genecatalog KO annotation with: -a")
  unless ( defined $opt_a );

#===============================================================================
my ( $profilein, $length, $annotation, $result );
$profilein  = $opt_i;
$length     = $opt_l;
$annotation = $opt_a;
$result     = $opt_o;

#===============================================================================
my ( %koanno, @geneid );
&genecatalog2ko( $annotation, \%koanno );
&genecatalog2id( $length, \@geneid );
&profile2ko( $profilein, \@geneid, \%koanno, $result );

#===============================================================================
sub profile2ko {
  my ( $profile, $geneid, $koanno, $result ) = @_;
  my ( $PR, @info, $i, %koprofile, @head, $j );
  if ( $profile =~ /\.gz$/ ) {
    $PR = IO::Uncompress::Gunzip->new( $profile, MultiStream => 1 )
      or die "read $profile $!\n";
  }
  else {
    open $PR, "<$profile" or die "read $profile $!\n";
  }
  chomp( $_ = <$PR> );
  @head = split /\t/;
  while (<$PR>) {
    chomp;
    @info = split /\t/;
    next unless ( defined $$koanno{ $$geneid[ $info[0] ] } );
    for ( $i = 1 ; $i < @head ; ++$i ) {
      $koprofile{ $$koanno{ $$geneid[ $info[0] ] } }[$i] += $info[$i];
    }
  }
  close $PR;
  open PR, ">$result" or die "write $result $!\n";
  print PR join "\t", @head;
  foreach $i ( sort keys %koprofile ) {
    print PR "\n$i";
    for ( $j = 1 ; $j < @head ; ++$j ) {
      print PR "\t$koprofile{$i}[$j]";
    }
  }
  print PR "\n";
  close PR;
}

#===============================================================================
sub genecatalog2id {
  my ( $genecatalog_length, $geneid ) = @_;
  my (@info);
  open IN, "<$genecatalog_length" or die "read $genecatalog_length $!\n";
  while (<IN>) {
    chomp;
    @info = split /\t/;
    $geneid->[ $info[0] ] = $info[1];
  }
  close IN;
}

#===============================================================================
sub genecatalog2ko {
  my ( $genecatalog_anno, $koanno ) = @_;
  my (@info);
  open IN, "<$genecatalog_anno" or die "read $genecatalog_anno $!\n";
  while (<IN>) {
    chomp;
    @info = split /\t/;
    $koanno->{ $info[0] } = $info[1];
  }
  close IN;
}

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
  Contact: $Contact
  Usage:
  \$perl $0 [options]
  -i  [str ]  genecatalog profile table
  -o  [str ]  ko profile for output
  -l  [str ]  genecatalog length for id
  -a  [str ]  genecatalog ko annotation
  -h  [help]
  \n";
  exit;
}
