#!/usr/bin/perl

# mergeNucmerCoords.pl
# written by Linnéa Smeds                      19 June 2017
# =========================================================
# Takes a nucmer coords file and merge anchors closer than
# some threshold. Print only the start, stop and scaffold
# name columns (6 in total, skip the header, the spaces,
# delimiters ("|") and the identity and length columns).
# =========================================================


use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $COORDS = $ARGV[0];
my $THRES = $ARGV[1];
my $OUT = $ARGV[2];


#Open outfile
open(OUT, ">$OUT");

# Go through the coords and merge adjacent lines if possible
# (first take care of the 5 line header)
open(IN, $COORDS);
for(my $i=0; $i<5; $i++) {
	my $header = <IN>;
#	print OUT $header;
}
my $cnt=0;
my ($ps1,$pe1,$ps2,$pe2,$lsum1,$lsum2,$minIDY,$plR,$plQ,$pR,$pQ,$pdir);
while(<IN>) {
	if($_ =~m/^\d+/) {
		$_=" ".$_;
	}
	my @tab = split(/\s+/,$_);

	if($cnt==0) {
		($ps1,$pe1,$ps2,$pe2,$plR,$plQ,$pR,$pQ)=($tab[1],$tab[2],$tab[4],$tab[5],$tab[12],$tab[13],$tab[15],$tab[16]);
		$lsum1=$tab[7];
		$lsum2=$tab[8];
		$minIDY=$tab[10];
		if($pe2-$ps2>0) {
			$pdir="+";
		}
		else {
			$pdir="-";
		}
	}
	else {
		my $thisdir;
		if($tab[5]-$tab[4]>0) {
			$thisdir="+";
		}
		else {
			$thisdir="-";
		}

		# If the scaffolds and orientation are the same and the distance is smaller than thres => merge!
		if($tab[15] eq $pR && $tab[16] eq $pQ && $pdir eq $thisdir && $tab[1]-$pe1<=$THRES && abs($tab[4]-$pe2)<=$THRES) {	
			$pe1=$tab[2];
			$pe2=$tab[5];
			$lsum1+=($tab[2]-$tab[1]+1);
			$lsum2+=(abs($tab[5]-$tab[4])+1);
			if($tab[10]<$minIDY) {
				$minIDY=$tab[10];
			}
		}
		# Not same scaffolds or just not close enough, print last and save new line
		else {
			print OUT $ps1."\t".$pe1."\t".$ps2."\t".$pe2."\t".$pR."\t".$pQ."\n";
			($ps1,$pe1,$ps2,$pe2,$plR,$plQ,$pR,$pQ)=($tab[1],$tab[2],$tab[4],$tab[5],$tab[12],$tab[13],$tab[15],$tab[16]);
			$lsum1=$tab[7];
			$lsum2=$tab[8];
			$minIDY=$tab[10];
			if($pe2-$ps2>0) {
				$pdir="+";
			}
			else {
				$pdir="-";
			}
		}
	}
	$cnt++;
}
# print last line
print OUT $ps1."\t".$pe1."\t".$ps2."\t".$pe2."\t".$pR."\t".$pQ."\n";
close(IN);
