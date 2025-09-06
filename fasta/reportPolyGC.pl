#!/usr/bin/perl

my $usage = "
# # # # # #
# reportPolyGC.pl
# written by Linnéa Smeds                  12 March 2015
# modification of replacePolyGC.pl, this only reports a
# bedfile with the different regions.
# ======================================================
# Takes a fasta file and scans it for stretches of homo-
# polymers, of a given size or longer. It looks at all
# four nucleotides, and returns a bed file with all 
# occurences listed. (A proper bed file, meaning starts
# from 0).
# ======================================================
# Usage: perl 
";

use strict;
use warnings;

# Input parameters
my $FASTA = $ARGV[0]; 
my $THRES = $ARGV[1];

my $time = time;

open(IN, $FASTA);

while(<IN>) {
	if($_ =~ m/^>/){
		my @tab = split(/\s+/, $_);
		my $head = $tab[0];
		$head =~ s/>//;
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

 		
        #C
        my  @temp=();
	    while($seq =~ m/(C{$THRES,})/gi){
	        push @temp, $-[0]."\t".$+[0]."\tC";	#@- and @+ are default parameters for keeping match positions
	    }
        # G
        while($seq =~ m/(G{$THRES,})/gi){
	    push @temp, $-[0]."\t".$+[0]."\tG";
	    }

		# Sort and print 
	    foreach my $pos (sort {$a <=> $b} @temp) {
	        print $head."\t".$pos."\n";
	    }
  	}
}
$time = time - $time;
print STDERR "Total time elapsed: $time sec\n";

