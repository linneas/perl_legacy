#!/usr/bin/perl

# findClosestGeneFromGFF.pl
# written by Linnéa Smeds                      22 July 2015
# =========================================================
# Takes a gff file (preferably only with exons or cds) and
# a list of positions that should be tested, returns the
# list with a column with distance to closest gene (0 if
# overlapping) and the gene name.
# Note! The script doesn't check the distance to the closest
# exon, but only save the first and last exon (or cds) of 
# each gene.
# =========================================================
#
#

use strict;
use warnings;
use List::Util qw(max min);
 
# Input parameters
my $GFF = $ARGV[0];
my $POSITIONS = $ARGV[1];	#Vcf-like format, scaffold in col1 and pos in col2

# Go through GFF
my %hash = ();
open(IN, $GFF);
my ($gene, $start, $stop, $scaf)=("","","","");
while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	if($gene eq "") {	#First line in file
		$gene=$tab[9];
		$start=min(@tab[3..4]);
		$stop=max(@tab[3..4]);
		$scaf=$tab[0];
	}
	else {	# All other lines
		if($tab[9] eq $gene && $tab[0] eq $scaf) {	#Found same gene again
			$start=min($start, @tab[3..4]);
			$stop=max($stop, @tab[3..4]);
		}
		else { #Found a new gene (or the same gene on a new scaffold), save the old one first!
			$hash{$scaf}{$start}{'stop'}=$stop;
			$gene=~s/[";]//g;
			$hash{$scaf}{$start}{'gene'}=$gene;
#			print STDERR "DEBUG: Save $scaf, $start - $stop, $gene\n";
#			$start=$start-10000;							#Used to get a regionfile for genes+/-10kb
#			$stop=$stop+10000;								#  " 
#			$start=max($start, 0);							#  " 
#			print STDERR "$scaf	$start	$stop	$gene\n";	#  "
			
			$gene=$tab[9];
			$start=min(@tab[3..4]);
			$stop=max(@tab[3..4]);
			$scaf=$tab[0];
		}	
	}
}
close(IN);
#Save the last gene
$gene=~s/[";]//g;
$hash{$scaf}{$start}{'stop'}=$stop;
$hash{$scaf}{$start}{'gene'}=$gene;
#print STDERR "DEBUG: Save $scaf, $start - $stop, $gene\n";
#$start=$start-10000;								#Used to get a regionfile for genes+/-10kb
#$stop=$stop+10000;									#  " 
#$start=max($start, 0);								#  " 
#print STDERR "$scaf	$start	$stop	$gene\n";	#  "


# Go through the position file!	
open(IN, $POSITIONS);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	my $dist = "NA";
	my $gene = "NA";
	if(defined($hash{$tab[0]})) {
		foreach my $key (sort {$a<=>$b} keys %{$hash{$tab[0]}}) {
	#		print STDERR "DEBUG: looking at scaff ".$tab[0]." ".$key." ".$hash{$tab[0]}{$key}{'end'}."\n";
			 if($hash{$tab[0]}{$key}{'stop'}<$tab[1]) {	#Check the closest gene to the left
			 	$dist=$tab[1]-$hash{$tab[0]}{$key}{'stop'};
			 	$gene=$hash{$tab[0]}{$key}{'gene'};
			 }
			 else {	
			 	if($key<=$tab[1]) {	#Gene is overlapping position
			 		$dist=0;
			 		$gene=$hash{$tab[0]}{$key}{'gene'};
			 	}
			 	else {
			 		if($dist eq "NA" || $dist>($key-$tab[1])) {
			 			$dist=$key-$tab[1];
			 			$gene=$hash{$tab[0]}{$key}{'gene'};
					}
				}
				last;	#we don't need to look further
			}
		}
	}
	print join("\t", @tab)."\t".$dist."\t".$gene."\n";
}
close(IN);




			
	
