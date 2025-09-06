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
my $fasta = $ARGV[0]; 
my $thres = $ARGV[1];

my $time = time;

open(IN, $fasta);
#open(OUT, ">$OUT");

while(<IN>) {
	if($_ =~ m/^>/){
		my @tab = split(/\s+/, $_);
		my $head = $tab[0];
		$head =~ s/>//;
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
 		
		# Find positions of poly-A
	    my @temp;
	    while($seq =~ m/(A{$thres,})/gi){
	        push @temp, $-[0]."\t".$+[0];   #@- and @+ are default parameters for keeping match positions
	    }
	    foreach my $pos (@temp) {
	        print $head."\t".$pos."\tA\n";
	    }

        #C
        @temp=();
	    while($seq =~ m/(C{$thres,})/gi){
	        push @temp, $-[0]."\t".$+[0];
	    }
	    foreach my $pos (@temp) {
	        print $head."\t".$pos."\tC\n";
	    }

        # G
	    @temp=();	 
        while($seq =~ m/(G{$thres,})/gi){
	    push @temp, $-[0]."\t".$+[0];
	    }
	    foreach my $pos (@temp) {
	        print $head."\t".$pos."\tG\n";
	    }
        # T
	    @temp=();	 
        while($seq =~ m/(T{$thres,})/gi){
	    push @temp, $-[0]."\t".$+[0];
	    }
	    foreach my $pos (@temp) {
	        print $head."\t".$pos."\tT\n";
	    }
	}
}
$time = time - $time;
print STDERR "Total time elapsed: $time sec\n";
