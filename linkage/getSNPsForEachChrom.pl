#!/usr/bin/perl

# # # # # #
# getSNPsForEachChrom.pl
# written by Linnéa Smeds, Oct 2012
# =========================================================
# Takes a scaffold list file with 5 or more columns (chrom, 
# scaffold, length, order, and some info), and list with
# SNPs for each scaffold (doesn't have to be sorted).
# Prints both a list of all SNPs sorted according to the
# scaffold list, and a summary of the number of SNPs for 
# a given window size.
# =========================================================


use strict;
use warnings;

# Input parameters
my $SCAFLIST = $ARGV[0];	#Five columns (chrom, scaff, length, sign, comment)
my $SNPFILE = $ARGV[1];		#SNPname, scaffold position, other columns 
my $WINDSIZE = $ARGV[2];
my $OUTPREFIX = $ARGV[3];

# Outfiles
my $summary = $OUTPREFIX."_".$WINDSIZE."wind.summary";
my $list = $OUTPREFIX."_sorted.txt";
open(SUM, ">$summary");
open(LIST, ">$list");

# Save all SNPS in a hash table
# (scaffold as primary key, position as secondary key)
my %SNPS = ();
open(IN, $SNPFILE);
my $header = <IN>;
print LIST $header;
my $cnt = 1;
while(<IN>) {
	my @tabs = split(/\s+/, $_);
	my $name = shift @tabs;
	my $scaffold = shift @tabs;
	my $position = shift @tabs;
	$SNPS{$scaffold}{$position}=join("\t",@tabs);
#	print "removing $name $scaffold and $position from hash\n";
}
close(IN);

	
# Go through the scaffold linkage list and extract
# the corresponding SNPs for each window
open(IN, $SCAFLIST);
while(<IN>) {
	my @tab = split(/\s+/, $_);

	# Make hash of windows 
	my %windows = ();
	for(my $i=1; $i<=$tab[2]; $i+=$WINDSIZE) {
		if($i+$WINDSIZE-1 <= $tab[2]) {
			$windows{$i}{'end'} = $i+$WINDSIZE-1;
		}
		else {
			$windows{$i}{'end'} = $tab[2];
		}		
		$windows{$i}{'array'} = [];
	}	

	# Save SNPS to windows
	if(defined $SNPS{$tab[1]}) {
		foreach my $key (sort {$a<=>$b} keys %{$SNPS{$tab[1]}}) {
			my $wind = int($key/$WINDSIZE)*$WINDSIZE+1;
		#	print $key." belongs to window $wind\n";
			push(@{$windows{$wind}{'array'}}, "$key\t".$SNPS{$tab[1]}{$key});
		}
	}

	# Print "+" oriented scaffolds
	if($tab[3] eq "+") {
		foreach my $start (sort {$a<=>$b} keys %windows) {
			my $cnt=0;
			my ($fixed, $Cpriv, $Ppriv, $shared, $cand) = (0,0,0,0,0);
			foreach my $temp (@{$windows{$start}{'array'}}) {
				my @t = split(/\s+/, $temp);
				my $pos = shift @t;
				print LIST $tab[1].":".$pos."\t".$tab[1]."\t".$pos."\t".join("\t",@t)."\n";
				if($t[0]==1) {
					$fixed+=1;
				}
				if($t[1]==1) {
					$Cpriv+=1;
				}
				if($t[2]==1) {
					$Ppriv+=1;
				}
				if($t[3]==1) {
					$shared+=1;
				}
				if($t[4]==1) {
					$cand+=1;
				}
				$cnt++;
			}
			print SUM $tab[1]."\t".$start."\t".$windows{$start}{'end'}."\t".$cnt.
						"\t".$fixed."\t".$Cpriv."\t".$Ppriv."\t".$shared."\t".$cand."\n";
		}
	}
	# Print "-" oriented scaffolds
	else {
		foreach my $start (sort {$b<=>$a} keys %windows) {
			my $cnt=0;
			my ($fixed, $Cpriv, $Ppriv, $shared, $cand) = (0,0,0,0,0);
			@{$windows{$start}{'array'}}=reverse(@{$windows{$start}{'array'}});
			foreach my $temp (@{$windows{$start}{'array'}}) {
				my @t = split(/\s+/, $temp);
				my $pos = shift @t;
				print LIST $tab[1].":".$pos."\t".$tab[1]."\t".$pos."\t".join("\t",@t)."\n";
				if($t[0]==1) {
					$fixed+=1;
				}
				if($t[1]==1) {
					$Cpriv+=1;
				}
				if($t[2]==1) {
					$Ppriv+=1;
				}
				if($t[3]==1) {
					$shared+=1;
				}
				if($t[4]==1) {
					$cand+=1;
				}
				$cnt++;
			}
			my $end = $start+$WINDSIZE-1;
			print SUM $tab[1]."\t".$start."\t".$windows{$start}{'end'}."\t".$cnt.
						"\t".$fixed."\t".$Cpriv."\t".$Ppriv."\t".$shared."\t".$cand."\n";
		}
	}
}
close(IN);
