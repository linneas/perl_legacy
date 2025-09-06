#!/usr/bin/perl


# # # # # #
# countGenesPerChrom.pl
# written by Linnéa Smeds 11 05 2011
# ===================================================
# Takes a output file from the Transcript Blast Pipe
# together with the reference gene list, and prints 
# out how many hit genes that belong to a certain
# chromosome.
# ===================================================
# Usage: 

use strict;
use warnings;


# Save the starting time
my $time = time;

# Input parameters
my $finalBlastList = $ARGV[0]; 	
my $reference = $ARGV[1];		
my $chromosome = $ARGV[2];

my %refHash = ();
open(REF, $reference);
while(<REF>) {
	if(/>/) {
		my @t = split(/\|/, $_);
		if($t[2] eq $chromosome) {
			my $name = $t[0]."|".$t[1];
			
			$name =~ s/>//g;
			$refHash{$name}=$t[2];
		}
	}
}
close(REF);

my $cnt = 0;
open(IN, $finalBlastList);
while(<IN>) {
	if(/>/) {
		my @t = split(/\|/, $_);
		my $name = $t[0]."|".$t[1];
		$name =~ s/>//g;
		if(defined $refHash{$name}) {
			$cnt++;
		}
	}
}

print "Number of hit genes on chromosome $chromosome: $cnt\n";

