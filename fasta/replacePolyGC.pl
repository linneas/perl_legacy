#!/usr/bin/perl

my $usage = "
# # # # # #
# replacePolyGC.pl
# written by Linnéa Smeds                       9 oct 2013
# ========================================================
# Takes a fasta file and finds and replaces all occurances
# of \"G\" or \"C\" longer than a given threshold with Ns. 
# ========================================================
# Usage: perl 
";

use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0]; 
my $thres = $ARGV[1];
my $OUT = $ARGV[2];

# Other parameters
my $rowlength = 100;

my $time = time;

open(IN, $fasta);
open(OUT, ">$OUT");

while(<IN>) {
	if($_ =~ m/^>/){
		my @tab = split(/\s+/, $_);
		my $head = $tab[0];
		my $seq = "";
		my $scafsum = 0;
		my $Ns = 0;

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

		my $length = length($seq);

		
		# Replace poly Gs and poly Cs by N (of the same length)
		$seq =~ s/(G{$thres,})/"N" x length($1)/gei;
		$seq =~ s/(C{$thres,})/"N" x length($1)/gei;

		my @seqParts = split(/(.{$rowlength})/, $seq);
		print OUT $head."\n";
		for my $seqs (@seqParts) {
			unless($seqs eq "") {
				print OUT $seqs."\n";
			}
		}
	}
}
$time = time - $time;
print "Total time elapsed: $time sec\n";
