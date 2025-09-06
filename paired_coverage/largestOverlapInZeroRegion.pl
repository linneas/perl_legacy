#!/usr/bin/perl

# largestOverlapInZeroRegion.pl
# written by Linnéa Smeds                       August 2011
# =========================================================
# Takes a list of zero regions and finds the largest
# possible overlap among left-side pairs and right-side
# pairs.
# =========================================================


use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $bam = $ARGV[0];
my $zeroList = $ARGV[1];
my $dist = $ARGV[2];
my $output = $ARGV[3];

open(OUT, ">$output");
open(IN, $zeroList);
my $rowCnt = 1;
my ($currScaff, $currEnd) = ("", "");
my $temp;
while(<IN>) {
	my ($scaff, $start, $end) = split(/\s+/,$_);
	my $size = $end-$start+1;

	my $temp = "$scaff.$start-$end.temp.sam";
	my $checkSt = max(0, $start-$dist);
	my $checkEnd = $end+$dist;

	my %sams = ();

#	print "looking at $scaff with start $start and end $end and creating tempfile $temp\n";

	system("samtools view -f 0x0002 $bam $scaff:$checkSt-$checkEnd |awk '(\$7==\"=\"){print}' >$temp");

	my ($maxLeftSide, $minRightSide, $maxLeftRead, $minRightRead) = (0,100000000, "-", "-");

	open(TMP, $temp);
	while(<TMP>) {
		my @tab = split(/\s+/, $_);

		my $maplen = 0;
		my @cigars = split(/(\d+\D)/, $tab[5]);
		for (my $i=0; $i<scalar(@cigars); $i++) {
			if($cigars[$i] =~ m/(\d+)M/) {
				$maplen+=$1;
			}
		}

		if($tab[8]>0){
			$sams{$tab[0]}{'left'}{'start'}=$tab[3];
			$sams{$tab[0]}{'left'}{'maplen'}=$maplen;
			$sams{$tab[0]}{'ins'}=$tab[8];
		}
		else {
			$sams{$tab[0]}{'right'}{'start'}=$tab[3];
			$sams{$tab[0]}{'right'}{'maplen'}=$maplen;
		}
	}
	close(TMP);
	system("rm $temp");
	
	foreach my $keys (keys %sams) {
		if(defined $sams{$keys}{'left'} && defined $sams{$keys}{'right'}) {	
	
			my $pairStart =min($sams{$keys}{'left'}{'maplen'}+$sams{$keys}{'left'}{'start'}-1, $sams{$keys}{'right'}{'start'});
			my $pairEnd =max($sams{$keys}{'left'}{'maplen'}+$sams{$keys}{'left'}{'start'}-1, $sams{$keys}{'right'}{'start'});

			if($pairEnd<=$start) {
				if($sams{$keys}{'right'}{'maplen'}+$sams{$keys}{'right'}{'start'}-1 >$maxLeftSide && $sams{$keys}{'right'}{'maplen'}+$sams{$keys}{'right'}{'start'}-1 > $start) {
					$maxLeftSide = $sams{$keys}{'right'}{'maplen'}+$sams{$keys}{'right'}{'start'}-1;
					$maxLeftRead = $keys;
				}
			}
			elsif($pairStart>=$end) {
				if($sams{$keys}{'left'}{'start'}<$minRightSide && $sams{$keys}{'left'}{'start'} < $end) {
					$minRightSide = $sams{$keys}{'left'}{'start'};
					$minRightRead = $keys;
				}
			}
		}
	}
	if($minRightSide == 100000000) {
		$minRightSide = $start;
	}
	if($maxLeftSide == 0) {
		$maxLeftSide = $end;
	}

	print OUT $scaff."\t".$start."\t".$end."\t".$maxLeftSide."\t".$minRightSide."\t(".$maxLeftRead.",".$minRightRead.")\n";
}

close(IN);
close(OUT);

