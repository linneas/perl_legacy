#!/usr/bin/perl

# findGeneRegionsFromGFF.pl
# written by Linnéa Smeds                       20 Aug 2015
# =========================================================
# Find all genes from a gff and print their start and stop
# (if a gene lies on two scaffolds, print two lines for it).
# =========================================================
#
#

use strict;
use warnings;
use List::Util qw(max min);
 
# Input parameters
my $GFF = $ARGV[0];
my $SCAFLEN = $ARGV[1];
my $OUTPREF = $ARGV[2];

# Save all scaflengths
my %scaffolds = ();
open(IN, $SCAFLEN);
while(<IN>) {
	chomp($_);
	my ($scaff, $len) = split(/\s+/, $_);
	$scaffolds{$scaff}=$len;
} 
close(IN);


# Go through GFF
my %hash = ();
open(IN, $GFF);
my ($gene, $start, $stop, $scaf, $strand)=("","","","","");
while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	if($gene eq "") {	#First line in file
		$gene=$tab[9];
		$strand=$tab[6];
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
			$hash{$scaf}{$start}{'strand'}=$strand;
			
			$gene=$tab[9];
			$strand=$tab[6];
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
$hash{$scaf}{$start}{'strand'}=$strand;


# Go through all genes and print to file
my $OUT1 = $OUTPREF.".geneRegions.txt";
open(OUT1, ">$OUT1");
foreach my $sc (keys %hash) {
	foreach my $st (keys %{$hash{$sc}}) {
		print OUT1 $sc."\t".$st."\t".$hash{$sc}{$st}{'stop'}."\t".$hash{$sc}{$st}{'strand'}."\t".$hash{$sc}{$st}{'gene'}."\n";
	}
}
close(OUT1);

# Go through all genes per scaffold and divide the stretch
# between the genes to down/upstream flanks respectively
my $OUT2 = $OUTPREF.".flankRegions.txt";
open(OUT2, ">$OUT2");
my($lastscaf, $lastgene, $lastend, $laststrand)=("","","","");
foreach my $sc (sort keys %hash) {
	foreach my $st (sort {$a<=>$b} keys %{$hash{$sc}}) {
		if($sc ne $lastscaf) {	#Found a new scaffold
			# First print the flank from the last gene to the end of the prev scaf
			# (only if this is not the first scaffold in the hash)
			my $stream = "";
			unless($lastscaf eq "") {
				if($laststrand eq "+") {
					$stream = "downstream";
				}
				elsif($laststrand eq "-") {
					$stream = "upstream";
				}
				else {
					die "NEW SCAFFOLD, PRINT END OF LAST! Laststrand is not defined for $lastscaf, $lastgene\n";
				}
				my $lst=$lastend+1;
				print OUT2 $lastscaf."\t".$lst."\t".$scaffolds{$lastscaf}."\t".$lastgene."\t".$stream."\n";
			}
			# Then print the flank from the start of this scaf to the start if this gene
			if($hash{$sc}{$st}{'strand'} eq "+") {
				$stream = "upstream";
			}
			elsif($hash{$sc}{$st}{'strand'} eq "-") {
				$stream = "downstream";
			}
			else {
				die "NEW SCAFFOLD, PRINT START OF THIS! This strand is not defined for $sc, $lastgene\n";
			}
			my $lend=$st-1;
			print OUT2 $sc."\t1\t".$lend."\t".$hash{$sc}{$st}{'gene'}."\t".$stream."\n";
		}
		else {	#Same scaffold as previous
		
			# Genes are NOT overlapping (if they are, there is no flank between them)
			if($st>$lastend) {
				my $midpoint = int(($st-$lastend)/2)+$lastend;
				#left part
				my $stream = "";
				if($laststrand eq "+") {
					$stream = "downstream";
				}
				elsif($laststrand eq "-") {
					$stream = "upstream";
				}
				else{
					die "Laststrand is not defined for $sc, $lastgene\n";
				}
				my $lst=$lastend+1;
				print OUT2 $lastscaf."\t".$lst."\t".$midpoint."\t".$lastgene."\t".$stream."\n";
			
				#right part
				if($hash{$sc}{$st}{'strand'} eq "+") {
					$stream = "upstream";
				}
				elsif($hash{$sc}{$st}{'strand'} eq "-") {
					$stream = "downstream";
				}
				else {
					die "This strand is not defined for $sc, ".$hash{$sc}{$st}{'gene'}."\n";
				}
				my $rst=$midpoint+1;
				my $rend=$st-1;
				print OUT2 $sc."\t".$rst."\t".$rend."\t".$hash{$sc}{$st}{'gene'}."\t".$stream."\n";
			}
		}
		# Redefine last gene
		($lastscaf,$lastgene,$lastend,$laststrand)=($sc,$hash{$sc}{$st}{'gene'},$hash{$sc}{$st}{'stop'},$hash{$sc}{$st}{'strand'});
	}
}
# Print the last flank of the very last gene
my $stream = "";
if($laststrand eq "+") {
	$stream = "downstream";
}
elsif($laststrand eq "-") {
	$stream = "upstream";
}
else {
	die "NEW SCAFFOLD, PRINT END OF LAST! Laststrand is not defined for $lastscaf, $lastgene\n";
}
my $lst=$lastend+1;
print OUT2 $lastscaf."\t".$lst."\t".$scaffolds{$lastscaf}."\t".$lastgene."\t".$stream."\n";
close(OUT2);
	
	
	
	
	
	



			
	
