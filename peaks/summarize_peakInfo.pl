#!/usr/bin/perl


# summarize_peakInfo.pl		  	  
# written by Linnéa Smeds                                14 May 2012
# ------------------------------------------------------------------
# 
# -----------------------------------------------------------------
# Usage: perl 
#

use strict;
use warnings;
use List::Util qw[min max];

# Input parameters
my $peakTable = $ARGV[0];
my $outfile = $ARGV[1];

#Change the window size here:
my $windSize = 200000;

#Open outfile
open(OUT, ">$outfile");
print OUT "PEAK_NO	CHROM	SCAFF	LEN(Mb)	CUM_START(Mb)\n";

#Go through window table
open(IN, $peakTable);
my $chrom = "";
my $peakNo = 1;
my $cumPos = 0;
while(<IN>) {
	unless(/CHROM	SCAFF/) {
		my @tab = split(/\s+/, $_);	

		#Same chrom as previous row
		if($tab[0] ne $chrom) {
			$chrom = $tab[0];
			$cumPos = 0;
		}
		
		#Found a peak (check next line as well)
		if($tab[4] == 1) {
#			print "DEBUG: Found a peak: ".$tab[0]." ".$tab[1]." ".$tab[2]."\n";

			my $peakSize = $tab[3]-$tab[2]+1;
			my $peakStart = $cumPos/1000000;
	
			my $next = <IN>;
			my @nexttab = split(/\s+/, $next);	
			while($tab[0] eq $nexttab[0] && $nexttab[4]==1) {
#				print "DEBUG:\tPeak continues!\n";
				$peakSize+=$nexttab[3]-$nexttab[2]+1;
				$cumPos+=$nexttab[3]-$nexttab[2]+1;
				if(eof(IN)) {
					last;
				}	
				$next = <IN>;
				@nexttab = split(/\s+/, $next);		
			}
			seek(IN, -length($next), 1);

			$peakSize=sprintf "%.2f", $peakSize/1000000;
			$peakStart = sprintf "%.2f", $peakStart;

			print OUT $peakNo."\t".$tab[0]."\t".$tab[1]."\t".$peakSize."\t".$peakStart."\n";
			$peakNo++;
		}
		$cumPos+=$tab[3]-$tab[2]+1;		
	}
}
close(IN);
close(OUT);
