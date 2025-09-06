#!/usr/bin/perl

# imputeDataInGTtable.pl  	
# written by Linnéa Smeds,                 7 March 2018
# =====================================================
# Takes a GT table and a list of the three top closest
# for each individual, and imputes a missing bp iff all
# three closest relatives are called on this position. 
# =====================================================
# usage perl getPairwiseDistanceFromGTtable.pl genotypes.txt tophits.txt imputedfile.out 2>log


use strict;
use warnings;

# Input parameters
my $GTFILE = $ARGV[0];		#The genotype file with all positions
my $TOPHITS = $ARGV[1];		# Three lines per ind, with hits in second column
my $OUT = $ARGV[2];


# Open top hits list and save the hits
my %hash=();
open(IN, $TOPHITS);
while(<IN>) {
	my @t = split(/\s+/, $_);
	$hash{$t[0]}{$t[1]}=0;
}
close(IN);


# Open outfile
open(OUT, ">$OUT");


# Open GT file, and first save the header and which ind is in which column!
my %headername=();
my %headerno=();
my %loghash=();
open(IN, $GTFILE);
my $first = <IN>;
my @head = split(/\s+/, $first);
for(my $i=0; $i<scalar(@head); $i++) {
	$headername{$head[$i]}=$i;
	$headerno{$i}=$head[$i];
	$loghash{$head[$i]}{"imp"}=0;
	$loghash{$head[$i]}{"fail"}=0;

}
print OUT $first;

# Then go through the rest of the lines!

my $cnt=0;
my $impCnt=0;
my $noImpCnt=0;
while(<IN>) {
	my @t=split(/\s+/, $_);
 	$cnt++;
	for(my $i=2; $i<scalar(@t); $i++) {

		# If site is missing:
		if($t[$i] eq "N") {
			my $ind=$headerno{$i};
#			print "DEBUG: Missing site ".$t[0].":".$t[1].", for ind $ind!\n";
			my $new="";
			my $flag="ok";
			foreach my $key (keys %{$hash{$ind}}) {
				my $this=$t[$headername{$key}];
#				print "DEBUG: ..check out relative $key with base $this\n";

				if($new eq "") {
					$new=$this;
				}
				else {
					unless($new eq $this) {
						$flag="bad";	
					}
				}
			}
			if($flag eq "ok" && $new ne "N") {
#				print "DEBUG: \tAll three closest relatives had the same base! Imputing $new\n";
				$impCnt++;
				$t[$i]=$new;
				$loghash{$ind}{"imp"}++;
				
			}
			else {
#				print "DEBUG: \tThe three closest the three closest relatives were incongruent, no imputation!\n";
				$noImpCnt++;
				$loghash{$ind}{"fail"}++;
			}
		}
	}
	print OUT join("\t", @t)."\n";

}
close(IN);

foreach my $key (sort keys %loghash) {
	print STDERR $key."\t".$loghash{$key}{"imp"}."\t".$loghash{$key}{"fail"}."\n";
}


print "Looked at $cnt sites\n";
print "imputed $impCnt bases and failed $noImpCnt bases\n";


