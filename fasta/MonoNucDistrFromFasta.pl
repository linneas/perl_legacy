#!/usr/bin/perl

my $usage = "
# # # # # #
# MonoNucDistrFromFasta.pl
# written by Linnéa Smeds, 11 Sept 2013
# based on the script NDistrFromFasta.pl from 19 oct 2010
# =======================================================
# Makes a list of all mono-nucleotide stretches of base X
# longer than a certain threshold, and prints a length 
# distribution of them.
# =======================================================
# Usage: perl MonoNucDistrFromFasta.pl <fastafile> <A|T|C|G> 
#			      <thres> <out>
#
# Example 1: perl MonoNucDistrFromFasta.pl mySeqs.fa G 4 Gtest
# 	(Returns a histogram with stretches of G longer than 4)";

use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0]; 
my $base = $ARGV[1];
my $thres = $ARGV[2];
my $out = $ARGV[3];

my $time = time;

my %hist = ();

open(OUT, ">$out");
open(IN, $fasta);
while(<IN>) {
	# Check each scaffold
	if($_ =~ m/^>/){
		my @tab = split(/\s+/, $_);
		my $seq = "";

		my $next = <IN>;
		while ($next !~ m/^>/) {
			chomp($next),
			$seq.= $next;
			if(eof(IN)) {
				last;
			}	
			$next = <IN>;
		}
		seek(IN, -length($next), 1);



		# Save occation if longer than thres
		my @hits = $seq =~ m/($base+)/gi;
		foreach my $hit (@hits) {
			if(length($hit)>$thres) {
				if(defined $hist{length($hit)}) {
					$hist{length($hit)}++;
				}
				else {
					$hist{length($hit)}=1;
				}
			}
		}	
	}
}

# Go through hash and print
foreach my $key (sort {$a<=>$b} keys %hist) {
		print OUT $key."\t".$hist{$key}."\n";
	}

$time=time-$time;
print "Total time elapsed: $time sec\n";

