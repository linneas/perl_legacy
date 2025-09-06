#!/usr/bin/perl

# checkingForOtherScaffoldLinksInZeroRegions.pl
# written by Linnéa Smeds                       August 2011
# =========================================================
# Takes a list of zero regions and checks if there are many
# reads around it mapping to other scaffolds. If so, this
# could be a sign of a real mis-assembly which will be fixed
# by splittning and re-scaffolding.
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

#	print "looking at $scaff with start $start and end $end and creating tempfile $temp\n";

	system("samtools view $bam $scaff:$checkSt-$checkEnd |awk '(\$7!=\"=\" && \$7!=\"*\"){print}' >$temp");

	my ($leftCnt, $rightCnt) = (0,0);
	my %lefties = ();
	my %righties = ();


	open(TMP, $temp);
	while(<TMP>) {
		my @tab = split(/\s+/, $_);
	
		if($tab[3]<$start) {
			$leftCnt++;
			if(defined $lefties{$tab[6]}) {
				$lefties{$tab[6]}++;
			}
			else {
				$lefties{$tab[6]}=1;
			}
		}
		elsif($tab[3]+length($tab[9])>$end) {
			$rightCnt++;
			if(defined $righties{$tab[6]}) {
				$righties{$tab[6]}++;
			}
			else {
				$righties{$tab[6]}=1;
			}
		}
	}
	close(TMP);
	system("rm $temp");
	
	if($leftCnt+$rightCnt>0) {

		my $maxleft = "-";
		my $maxleftno = ""; 
		foreach my $keys (sort {$lefties{$b}<=>$lefties{$a}} keys %lefties) {
			$maxleft = $keys;
			$maxleftno = "(".$lefties{$keys}.")";	
			last;
		}
		my $maxright = "-";
		my $maxrightno = "";
		foreach my $keys (sort {$righties{$b}<=>$righties{$a}} keys %righties) {
			$maxright = $keys;	
			$maxrightno = "(".$righties{$keys}.")";	
			last;
		}
	

		print OUT $scaff."\t".$start."\t".$end."\t".$leftCnt."\t".$maxleft.$maxleftno."\t".$rightCnt."\t".$maxright.$maxrightno."\n";
	}

}
close(IN);
close(OUT);

