#!/usr/bin/perl

# getPairwiseDistanceFromGTtable.pl  	
# written by Linnéa Smeds,                 7 March 2018
# =====================================================
# Takes a GT table and calculates pairwise distances
# between all pairs of individuals. The script prints
# two lines for each comparison, so that all individuals
# have the same number of occurances in column one (and
# we can find the best matches for each just by sorting
# on col1, 3 and 4.
# =====================================================
# usage perl getPairwiseDistanceFromGTtable.pl genotypes.txt 


use strict;
use warnings;

# Input parameters
my $GTFILE = $ARGV[0];		#The genotype file with all positions
my $OUT = $ARGV[1];
my %hash=();

# Open out
open(OUT, ">$OUT");


# Open GT file, and first save the name of all individuals
open(IN, $GTFILE);
my $first = <IN>;
my @header = split(/\s+/, $first);
shift @header;	# Remove "CHROM"
shift @header;	# Remove "POS"

my $c=0;
for(my $i=0; $i<scalar(@header); $i++) {

	$hash{$i}{"name"}=$header[$i];
#	print "DEBUG: save ".$header[$i]." to hash index $i\n";
	$c++;
}
#print "DEBUG: saved $c individuals to hash!\n";

# Then go through the positions and save the letters
my $cnt=0;
while(<IN>) {
	my @tabs=split(/\s+/, $_);
	shift @tabs;
	shift @tabs;
 	$cnt++;
	for(my $i=0; $i<scalar(@header); $i++) {
		$hash{$i}{$cnt}=$tabs[$i];
	}
}
close(IN);
#print "DEBUG: Added $cnt positions!\n";

# Go through all individual pairs and check the number of differences!
my $max=scalar(keys %hash);
my $comp = 0;
#print "DEBUG: Go through index 1 to $max, looking at ind ". $hash{0}{"name"}." to ".$hash{$max-1}{"name"}."\n";

for(my $i=0; $i<$max-1; $i++) {
	for(my $j=$i+1; $j<$max; $j++) {
#		print "DEBUG: Compare ".$hash{$i}{"name"}."\t".$hash{$j}{"name"}."\n";
		$comp++;
		my $tot=0;
		my $diff=0;

		for(my $k=1; $k<=$cnt; $k++) {
			unless($hash{$i}{$k}) {
				print "Undefined value for ".$hash{$i}{"name"}." position $k!\n";
			}
			unless($hash{$i}{$k} eq "N" || $hash{$j}{$k} eq "N") {
				$tot++;
				if($hash{$i}{$k} ne $hash{$j}{$k}) {
					$diff++;
				}
			}	
		}
		
		# Print result
		my $ratio=$diff/$tot;
		
		print OUT $hash{$i}{"name"}."\t".$hash{$j}{"name"}."\t".$ratio."\t".$tot."\t".$diff."\n";
		print OUT $hash{$j}{"name"}."\t".$hash{$i}{"name"}."\t".$ratio."\t".$tot."\t".$diff."\n";
	}
}

print "Made $comp pairwise comparisons\n";


