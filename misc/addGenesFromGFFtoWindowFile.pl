#!/usr/bin/perl


# # # # # #
# addGenesFromGFFtoWindowFile.pl
# written by Linnéa Smeds                      31 Oct 2011
# ========================================================
# 
# ========================================================
# Usage: perl 
#
# Example: 

use strict;
use warnings;

# Input parameters
my $GFF = $ARGV[0];
my $WINDFILE = $ARGV[1];
my $windsize = $ARGV[2];
my $OUT = $ARGV[3];

my %genePos = ();
open(IN, $GFF);
while(<IN>) {
	unless(/^#/) {
		my @tab = split(/\s+/, $_);
		for(my $i=$tab[3]; $i<=$tab[4]; $i++) {
			$genePos{$tab[0]}{$i}=1;
		}
	}
}
close(IN);

open(OUT, ">$OUT");
open(WIN, $WINDFILE);
my $head = <WIN>;
chomp($head);
print OUT $head."\tCDSs\tCDSfrac\n";
while(<WIN>) {
	my @tab = split(/\s+/, $_);
	my $cnt=0;
	foreach my $key (keys %{$genePos{$tab[0]}}) {
		if($key>=$tab[1] && $key<=$tab[2]) {
			$cnt++;
			delete $genePos{$tab[0]}{$key};
		}
	}
	my $percent = $cnt/$windsize;
	chomp($_);
	print OUT $_."\t".$cnt."\t".$percent."\n";
}


