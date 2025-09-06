#!/usr/bin/perl -w


# mergePeakWindows.pl		  	  
# written by Linnéa Smeds                               Jan 2011
# --------------------------------------------------------------
# Takes a list of windows in peak regions and prints all windows 
# from one peak on one line. Can either include all windows or
# only windows of a certain size. Set the thres flag as wanted.
# --------------------------------------------------------------
# Usage: perl mergePeakWindows.pl <peakfile> <thres> <output> 
#
# Example:  perl mergePeakWindows.pl peaks_1e-3.txt 1 \
#					summary_1e-3.txt 

use strict;

# Input parameters
my $infile = $ARGV[0];
my $thres = $ARGV[1];
my $outfile = $ARGV[2];


open(OUT, ">$outfile");
# Go through the infile line by line
open(IN,$infile);
while(<IN>) {

	my @tab = split(/\s+/, $_);
	my $endflag="off";

	if($tab[3]-$tab[2]>=$thres) {

		my ($chr, $scaf, $start, $end) = ($tab[0], $tab[1], $tab[2], $tab[3]);

		my $tempCov=$tab[4]*($tab[3]-$tab[2]+1);
		my $tempGC=$tab[5]*($tab[3]-$tab[2]+1);
		my $tempRep=$tab[6]*($tab[3]-$tab[2]+1);
		my $Ns=$tab[7];
		my $basesCov=$tab[8];

		if(eof(IN)) {
			last;
		}
		my $next = <IN>;
		my @nexttab = split(/\s+/, $next);
		
		while ($nexttab[1] eq $scaf && ($nexttab[2]-$end==1 || 
			$start-$nexttab[3]==1) && $nexttab[3]-$nexttab[2]>=$thres) {
			$tempCov+=$nexttab[4]*($nexttab[3]-$nexttab[2]+1);
			$tempGC+=$nexttab[5]*($nexttab[3]-$nexttab[2]+1);
			$tempRep+=$nexttab[6]*($nexttab[3]-$nexttab[2]+1);
			$Ns+=$nexttab[7];
			$basesCov+=$nexttab[8];
			if($nexttab[2]>$end) {
				$end = $nexttab[3];
			}
			else{
				$start = $nexttab[2];
			}

			if(eof(IN)) {
				last;
				$endflag="on";
				print "Nu är det sista raden $scaf $start\n";
			}	
			$next = <IN>;
			@nexttab = split(/\s+/, $next);
		}
		if($endflag eq "off") {
			seek(IN, -length($next), 1);
		
			my $meanCov=$tempCov/($end-$start+1);
			my $meanRep = $tempRep/($end-$start+1);
			my $meanGC = $tempGC/($end-$start+1);
		
			print OUT $chr."\t".$scaf."\t".$start."\t".$end."\t".$meanCov."\t".$meanGC."\t".$meanRep."\t".$Ns."\t".$basesCov."\n";
		}
	}
}
close(IN);
close(OUT);

