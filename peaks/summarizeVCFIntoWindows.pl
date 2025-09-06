#!/usr/bin/perl

# summarizeVCFIntoWindows.pl  	
# written by Linnéa Smeds,                30 March 2012
# =====================================================
# Takes a VCF file (or any kind of file with scaff/chrom
# in first column and 
# =====================================================
# usage perl


use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0];	# At least two columns: sequence name and position
my $WINDOWS = $ARGV[1];	# At least three columns: sequence name, start and stop 
my $OUTPUT = $ARGV[2];

# Save the positions in a hash
my %positions = ();
open(IN, $VCFFILE);
while(<IN>) {
	my @tab=split(/\s+/, $_);
	$positions{$tab[0]}{$tab[1]}=1;
}
close(IN);

# Go through windows 
open(OUT, ">$OUTPUT");
open(IN, $WINDOWS);
while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/, $_); 

	my $tempCnt=0;

	foreach my $key (sort keys %{$positions{$tab[0]}}) {
		if($key >= $tab[1] && $key <= $tab[2]) {
			$tempCnt++;
		}
	}

	print OUT $_."\t".$tempCnt."\n";
}
close(IN);
close(OUT);
