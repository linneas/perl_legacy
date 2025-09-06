#!/usr/bin/perl


# # # # # #
# findBlocksFromGRIMM.pl
# written by Linnéa Smeds                    Oct 2012
# ===================================================
# Makes the opposite compared to makeGRIMMinput, gets
# the original positions from the scaffolds and sorts
# the blocks in numerical order based on their pos.
# ===================================================
# Usage: 

use strict;
use warnings;
use List::Util qw(max min);


# Input parameters
my $GRIMMBLOCK = $ARGV[0];
my $KARYOTYPE = $ARGV[1];
my $SCAFLIST = $ARGV[2]; 		
my $OUTPREF = $ARGV[3];
my $EDGEkb = 10;


# Output files
my $OUTBLOCKS = $OUTPREF."_SortedBlocks.txt";
my $OUTEDGE = $OUTPREF."_Edge".$EDGEkb."kb.txt";
my $OUTLIST = $OUTPREF."_rearrRegions.txt";


#Save karyotype
my %hashmap = ();
open(IN, $KARYOTYPE);
my $scafCnt=1;
my $start = 0;
while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	$hashmap{$tab[2]}{'length'}=$tab[5];
	$hashmap{$tab[2]}{'start'}=$start;
	$hashmap{$tab[2]}{'order'}=$scafCnt;
	$start+=$tab[5];
	$scafCnt++;
}
close(IN);


# Save scaffold orientations
open(IN, $SCAFLIST);
while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	if(defined $hashmap{$tab[1]}) {
		$hashmap{$tab[1]}{'dir'}=$tab[3];
	}
}
close(IN);


# Go through the blocks and save start and stop on scaffold pos
open(IN, $GRIMMBLOCK);
my %blocks = ();
my $printflag = "off";
my $cnt = 1;
while(<IN>) {
	unless(/^#/) {
		my @tab = split(/\s+/, $_);
		my ($pos1, $pos2);
		my $length = $tab[7];

		my ($start1,$scaffold1,$start2,$scaffold2);

#		print "lookin at block with start ".$tab[6]."\n";	

		foreach my $key (sort {$hashmap{$b}{'start'}<=>$hashmap{$a}{'start'}} keys %hashmap) {
	#		print "now looking at ".$key." with start ".$hashmap{$key}{'start'}."\n";
			$scaffold1 = $key;
			$start1 = $hashmap{$key}{'start'};
			if($tab[6]>$start1) {
#				print "found the first one smaller than pos!\n";
				last;
			}
		}

		foreach my $key (sort {$hashmap{$b}{'start'}<=>$hashmap{$a}{'start'}} keys %hashmap) {
#			print "now looking at ".$key." with start ".$hashmap{$key}{'start'}."\n";
			$scaffold2 = $key;
			$start2 = $hashmap{$key}{'start'};
			if(($tab[6]+$tab[7]-1)>$start2) {
#				print "found the first one smaller than pos!\n";
				last;
			}
		}

#		print "DEBUG: Looking at $start1 $scaffold1 $start2 $scaffold2\n";

		$pos1 = $tab[6]-$start1;
		$pos2 = $tab[6]+$tab[7]-1-$start2;

		unless(defined $hashmap{$scaffold1}{'dir'}) {
			print "the scaffold1 $scaffold1 is not defined in the scafmap\n";
		}
		unless(defined $hashmap{$scaffold2}{'dir'}) {
			print "the scaffold2 $scaffold2 is not defined in the scafmap\n";
		}

	
		if($hashmap{$scaffold1}{'dir'} eq "-") {
			$pos1 = $hashmap{$scaffold1}{'length'}-$pos1+1;
		}
		if($hashmap{$scaffold2}{'dir'} eq "-") {
			$pos2 = $hashmap{$scaffold2}{'length'}-$pos2+1;
		}

		$blocks{$scaffold1}{$pos1}{'endscaf'}=$scaffold2;
		$blocks{$scaffold1}{$pos1}{'endpos'}=$pos2;
		$blocks{$scaffold1}{$pos1}{'len'}=$length;
		$blocks{$scaffold1}{$pos1}{'cnt'}=$cnt;
		$cnt++;
	}
}
close(IN);


# Sort the blocks along the scaffolds and print
open(OUT, ">$OUTBLOCKS");
print OUT "#NO	START	STARTPOS END	ENDPOS	LENGTH\n";


foreach my $key (sort {$hashmap{$a}{'order'}<=>$hashmap{$b}{'order'}} keys %hashmap) {
	if(defined $blocks{$key}) {
		if($hashmap{$key}{'dir'} eq "+") {
			foreach my $subkey (sort {$a<=>$b} keys %{$blocks{$key}}) {
#				print "in IF subkeys is $subkey\n";
				print OUT $blocks{$key}{$subkey}{'cnt'}."\t".$key."\t".$subkey."\t".
				$blocks{$key}{$subkey}{'endscaf'}."\t".$blocks{$key}{$subkey}{'endpos'}."\t".
				$blocks{$key}{$subkey}{'len'}."\n";

			}
		}
		else {
			foreach my $subkey (sort {$b<=>$a} keys %{$blocks{$key}}) {
#				print "in ELSE subkeys is $subkey\n";
				print OUT $blocks{$key}{$subkey}{'cnt'}."\t".$key."\t".$subkey."\t".
				$blocks{$key}{$subkey}{'endscaf'}."\t".$blocks{$key}{$subkey}{'endpos'}."\t".
				$blocks{$key}{$subkey}{'len'}."\n";
			}
		}
	}
}
close(OUT);


# Look at the regions between the blocks 
# For BedTools compatibility, the segments are
# always printed with the smallest pos first

open(OUT, ">$OUTLIST");
open(OUT2, ">$OUTEDGE");
open(IN, $OUTBLOCKS);
my $blCnt = 1;
my ($prevScaf,$prevPos);
my ($totlen, $no) = (0,0);
while(<IN>) {
	unless(/^#/) {
		my @tab = split(/\s+/,$_);
		
		unless($blCnt==1) {
			my ($start, $stop);
			my $length = 0;

			#First, print the edges!

			# Left edge
			if($hashmap{$prevScaf}{'dir'} eq "+") {
				my $firststart = max($prevPos-($EDGEkb*1000-1), 1);
				print OUT2 $prevScaf."\t".$firststart."\t".$prevPos."\n";
			}
			else {
				my $firstend = min($prevPos+($EDGEkb*1000-1), $hashmap{$prevScaf}{'length'});
				print OUT2 $prevScaf."\t".$prevPos."\t".$firstend."\n";
			}

			# Right edge
			if($hashmap{$tab[1]}{'dir'} eq "+") {
				my $lastend = min($tab[2]+($EDGEkb*1000-1), $hashmap{$tab[1]}{'length'});
				print OUT2 $tab[1]."\t".$tab[2]."\t".$lastend."\n";
			}
			else {
				my $laststart = max($tab[2]-($EDGEkb*1000-1), 1);
				print OUT2 $tab[1]."\t".$laststart."\t".$tab[2]."\n";
			}


			#Then, print the breaks			

			# The region is within a scaffold
			if($tab[1] eq $prevScaf) {
				$start = min($prevPos,$tab[2]);
				$stop = max($prevPos,$tab[2]);
				$start+=1;
				$stop-=1;
#				print "DEBUG: Looking at region within a scaffold: $prevScaf\n";				
			}
			#The region is spanning a break between scaffolds
			else {

#				print "DEBUG: Looking at region between scaffolds: $prevScaf ".$tab[1]."\n";			

				#First part of gap
				if($hashmap{$prevScaf}{'dir'} eq "+") {
					$start = $prevPos+1;
					$stop = $hashmap{$prevScaf}{'length'};
				}
				else{
					$start = 1;	#"wrong" order on purpose 
					$stop = $prevPos-1;
				}
				#Doesn't print if the gap is "negative"
				unless($start>$stop) {
					print OUT $prevScaf."\t".$start."\t".$stop."\n";
					$length=$stop-$start+1;
				}
				#Second part of gap
				if($hashmap{$tab[1]}{'dir'} eq "+") {
					$start = 1;
					$stop = $tab[2]-1;
#					print "DEBUG: second part of gap: scaffold is +!\n";
				}
				else {
					$start = $tab[2]+1;		#"wrong" order on purpose
					$stop = $hashmap{$tab[1]}{'length'};
#					print "DEBUG: second part of gap: scaffold is -!\n";
#					print "   start is $start and stop is $stop\n";
				}
			}
			#Doesn't print if the gap is "negative"
			unless($start>$stop) {
				$length+=$stop-$start+1;
				print OUT $tab[1]."\t".$start."\t".$stop."\n";
			}
			$no++;
			$totlen+=$length;
			
		}
		$prevScaf = $tab[3];
		$prevPos = $tab[4];

		$blCnt++;
	}
}
close(IN);
close(OUT);

my $meanlength = "-";
if($no>0) {
	$meanlength = int($totlen/$no+0.5);
}
print "Mean between block size: $meanlength\n";



