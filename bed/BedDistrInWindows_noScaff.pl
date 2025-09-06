#!/usr/bin/perl

# BedDistrInWindows_noScaff.pl  	
# written by Linnéa Smeds,                  19 Feb 2014
# Modified 10 July 2014 so it works with a window file
# WITHOUT scaffolds! (need chr, start, stop)
# =====================================================
# Takes a BED file and a windows file, and checks how
# much of th bed content end up in each window.
# NOTE! The regions in the BED file CAN'T OVERLAP!!!
# This version does not keep track on if bases are cov
# twice, which means the content could exceed 100%.
# If having overlapping regions (like genes), use the
# other more memory demanding version.
# =====================================================
# usage perl BedDistrInWindows.pl file.bed wind.txt output  	

use strict;
use warnings;

# Input parameters
my $BEDFILE = $ARGV[0];	# At least three columns: sequence name, start and stop 
my $WINDOWS = $ARGV[1];	# THREE columns: Chrom, window start and window stop 
my $OUTPUT = $ARGV[2];

my $time=time;

# Open outfile handle
open(OUT, ">$OUTPUT");


# Save the windows in a hash
my %windows = ();
my $cnt=1;
open(WIND, $WINDOWS);
while(<WIND>) {
	chomp($_);
	my ($chr, $start, $end) = split(/\s+/, $_); 
	$windows{$chr}{$start}{'end'}=$end;
	$windows{$chr}{$start}{'sum'}=0;
	$cnt++;
}
close(WIND);


# Go through the regions
open(IN, $BEDFILE);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	my $chr=$tab[0];
	my $start=$tab[1];
	my $end=$tab[2];
	# Check if scaffold exist in window list 
	if(defined $windows{$chr}) {
#			print "DEBUG: Looking at region $chr $start-$end\n";

		# Go through each window in order
		foreach my $st (sort {$a<=>$b} keys %{$windows{$chr}}) {
			
			# Region cover full window
			if($start<$st && $end>$windows{$chr}{$st}{'end'}) {
#				print "\tregion cover full window starting on $st\n";
				$windows{$chr}{$st}{'sum'}=$windows{$chr}{$st}{'end'}-$st+1;
			}
			# Region cover start, but not end
			elsif($start<$st && $end>=$st && $end<$windows{$chr}{$st}{'end'}) {
#				print "\tregion cover start but not end $st\n";
				$windows{$chr}{$st}{'sum'}+=$end-$st+1;
			}
			# Region lies completely within the window
			elsif($start>=$st && $end<=$windows{$chr}{$st}{'end'}) {
#					print "\tregion lies within window starting on $st\n";	
					$windows{$chr}{$st}{'sum'}+=$end-$start+1;
			}
			# Region cover end, but not start
			elsif($start>$st && $start<=$windows{$chr}{$st}{'end'} && $end>$windows{$chr}{$st}{'end'}) {
#				print "\tregion cover end of window starting on $st\n";
				$windows{$chr}{$st}{'sum'}+=$windows{$chr}{$st}{'end'}-$start+1;
			}
			# Past the interesting windows, skip the rest!
			elsif($st > $end){
				last;
			}
		}
	}
}
close(IN);


# Go through the window again and print result from the hash
open(WIND, $WINDOWS);
while(<WIND>) {
	chomp($_);
	my ($chr, $start, $end) = split(/\s+/, $_); 
	my $val = $windows{$chr}{$start}{'sum'}/($end-$start+1);
	print OUT $_."\t".$val."\n";
}

$time=time-$time;
print "Total time elapsed: $time sec\n";
