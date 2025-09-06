#!/usr/bin/perl


# # # # # #
# countGenesPerChrom.pl
# written by Linnéa Smeds 11 05 2011
# ===================================================
# Takes a output file from the Transcript Blast Pipe
# together with the reference gene list, and prints 
# a list with chromosomes and the corresponding number
# of hits.
# ===================================================
# Usage: 

use strict;
use warnings;


# Save the starting time
my $time = time;

# Input parameters
my $finalBlastList = $ARGV[0]; 	
my $reference = $ARGV[1];		

my %refHash = ();
open(REF, $reference);
while(<REF>) {
	if(/>/) {
		my @t = split(/\|/, $_);
		my $name = $t[0]."|".$t[1];	
		$name =~ s/>//g;
		$refHash{$name}=$t[2];
	}
}
close(REF);

my %cntHash = ();
open(IN, $finalBlastList);
while(<IN>) {
	if(/>/) {
		my @t = split(/\|/, $_);
		my $name = $t[0]."|".$t[1];
		$name =~ s/>//g;
		if(defined $refHash{$name}) {
			if(defined $cntHash{$refHash{$name}}) { 
				$cntHash{$refHash{$name}}++;
			}
			else {
				$cntHash{$refHash{$name}}=1;
			}
		}
	}
}
print "Chrom\t#Genes\n";
foreach my $key (sort {$a<=>$b} keys %cntHash) {
	print $key ."\t". $cntHash{$key} ."\n";
}
