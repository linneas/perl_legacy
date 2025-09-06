#!/usr/bin/perl

my $usage = "
# # # # # #
# getRecombRateForBreaks.pl
# Author: Linnéa Smeds                            6 Feb 2013
# ==========================================================
# Takes a list of breakpoints and a list of windows with
# recombination rates estimates and prints the rate (or the
# mean rate if several windows are involved) for each break.
#===========================================================\n";

use strict;
use warnings;
use List::Util qw(min max); 

# Input parameters
my $BREAKS = $ARGV[0];
my $RECOMB = $ARGV[1];
my $OUT = $ARGV[2];

# Outfile
open(OUT, ">$OUT");
print OUT "CHR	START	STOP	REC	DEF_WIND	UNDEF_WIND\n";


# Make hash of the windows
my %wind = ();
open(IN, $RECOMB);
while(<IN>) {
	my ($chr, $start, $stop, $rate) = split(/\s+/, $_);

	$wind{$chr}{$start}{'stop'}=$stop;
	$wind{$chr}{$start}{'rate'}=$rate;
	$wind{$chr}{$start}{'break'}="-";
}
close(IN);


# Go through the breakpoints
open(IN, $BREAKS);
while(<IN>) {
	my ($chr, $start, $stop) = split(/\s+/, $_);

	my ($noDef, $noNA) = (0, 0);

	my $cM = 0;
	my $bp = 0;	

	foreach my $key (sort {$a<=>$b} keys %{$wind{$chr}}) {
		if($start<$key && $stop>=$key) {	#overlapping with start of window
			my $len = min($stop-($key-1), $wind{$chr}{$key}{'stop'}-($key-1));
			if ($wind{$chr}{$key}{'rate'} eq "NA") {
				$noNA++;
			}
			else {
				$noDef++;
				$bp+=$len;
				$cM+=($len/1000000)*$wind{$chr}{$key}{'rate'};
				print "For $chr, adding $cM cM for $bp bases\n";
			}
			$wind{$chr}{$key}{'break'}="X";
		}
		elsif($start>=$key && $start<=$wind{$chr}{$key}{'stop'}) {
			my $len = min($stop-($start-1), $wind{$chr}{$key}{'stop'}-($start-1));
			if ($wind{$chr}{$key}{'rate'} eq "NA") {
				$noNA++;
			}
			else {
				$noDef++;
				$bp+=$len;
				$cM+=($len/1000000)*$wind{$chr}{$key}{'rate'};
				print "For $chr, adding $cM cM for $bp bases\n";
			}
			$wind{$chr}{$key}{'break'}="X";

		}
	}

	my $rate = "NA";
	unless($bp==0) {
		$rate = $cM/($bp/1000000);
	}

	print OUT $chr."\t".$start."\t".$stop."\t".$rate."\t".$noDef."\t".$noNA."\n";		
}
close(IN);
close(OUT);


my $recOUT = $RECOMB;
$recOUT =~ s/.txt/withBreakMark.txt/;
open(OUT, ">$recOUT");

open(IN, $RECOMB);
while(<IN>) {
	my ($chr, $start, $stop, $rate) = split(/\s+/, $_);
	my $break = $wind{$chr}{$start}{'break'};
	print OUT $chr."\t".$start."\t".$stop."\t".$rate."\t".$break."\n";
}
close(IN);
close(OUT);



