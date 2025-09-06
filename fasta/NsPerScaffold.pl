#!/usr/bin/perl


# # # # # #
# NsPerScaffold.pl
# written by Linnéa Smeds                      Sept 2011
# ======================================================
# Prints the name of the scaffold, the length and the 
# number and percentage of Ns. 
# ======================================================
# Usage: 

use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0]; 

open(IN, $fasta);
while(<IN>) {
	if($_ =~ m/^>/){
		my @tab = split(/\s+/, $_);
		my $head = $tab[0];
		chomp($head);
		$head =~ s/>//;
		my $seq = "";
		my $sum = 0;
	
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

		#Only sum up the number of N:s	
		my @hits = $seq =~ m/(N+)/gi;
		for(@hits) {
			$sum+=length($_);
		}	
		
		my $seqlen = length($seq);
		my $frac = $sum/$seqlen;
		print $head."\t".$seqlen."\t".$sum."\t".$frac."\n";
	}
}
close(IN);

