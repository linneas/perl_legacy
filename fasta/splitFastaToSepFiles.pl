#!/usr/bin/perl


# # # # # #
# splitFastaToSepFiles.pl
# written by Linnéa Smeds                    March 2014
# =====================================================
# Splits all the sequences in a fasta to separate files
# with the sequence names as file names.
# =====================================================
# Usage: 



use strict;
use warnings;

# Input parameters
my $FASTA = $ARGV[0];

#Go through fasta file, extract sequences
open(IN, $FASTA);
my $cnt=0;
while(<IN>) {
	if($_ =~ m/^>/) {
		if($cnt>0) {
			close(OUT);
		}
		my @tab = split(/\s+/, $_);
		my $head = $tab[0];
		$head=~s/>//;
		my $file=$head.".fa";
		open(OUT, ">$file");

		print OUT $_;
		$cnt++;
	}
	else {
		print OUT $_;
	}
}
close(OUT);
close(IN);
