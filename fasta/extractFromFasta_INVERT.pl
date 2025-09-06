#!/usr/bin/perl


# # # # # #
# extractFromFasta_INVERT.pl
# written by Linnéa Smeds May 2010, mod Feb 2011
# =====================================================
# Extracts sequences from a fasta file that are NOT on
# the given list.
# =====================================================
# Usage: extractFromFasta.pl <seqfile.fa> <list.txt>
#
# Example: extractFromFasta.pl mySeq.fa "contigsIdontWant.list" \
#		>myNewSeq.fa

use strict;
use warnings;

# Input parameters
my $scaffold_file = $ARGV[0];
my $query = $ARGV[1];

# Save wanted fasta headers
my %list=();

open(IN, $query);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	$tab[0]=~s/>//;
	$list{$tab[0]} = 1;
}

#Go through fasta file, extract sequences
open(IN, $scaffold_file);
my $seq = "";
my $flag = "off";
while(<IN>) {
	if($_ =~ m/^>/) {
		my @tab = split(/\s+/, $_);
		my $head = $tab[0];
		$head=~s/>//;

		if(defined $list{$head}) {
			$flag = "off";
		}
		else {
			print $_;
			$flag = "on";
		}
	}
	else {

		if($flag eq "on") {
			print $_;
		}
	}
}

