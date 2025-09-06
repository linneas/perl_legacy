#!/usr/bin/perl

# 
# written by Linnéa Smeds                         Nov 2016
# ========================================================
# Takes a samfile and a fasta with wanted scaffolds, and 
# check if each read is mapped to a wanted scaffold (other-
# wise throw away) and also control the mate - if mate
# maps to different scaffold, set mate to unmapped! 
# (By replacing the 7th column by "=" and also add "8" to
# the flag in column 2 (8="mate unmapped"). 
# If header is present, it's also filtered for unwanted 
# sequences. 
# ========================================================


use strict;
use warnings;

my $SAM = $ARGV[0];
my $FASTA = $ARGV[1];	#reference with approved scaffolds

my $time = time;

my %hash = ();
open(FST, $FASTA);
while(<FST>) {
	if(/^>/) {
		my @a=split(/\s+/, $_);
		my $scaf=$a[0];
 		$scaf=~s/>//;
		$hash{$scaf}=1;
	}
}
close(FST);

my $hashCnt = scalar(keys %hash);
print STDERR "There are $hashCnt scaffolds in the reference\n";

my $totCnt=0;
my ($badreadcnt,$badmatecnt)=(0,0);
open(SAM, $SAM);
while(<SAM>) {

	if(/^@/) {
		if(/^\@SQ/) {	#sequence header, check if it's in the hash!
			my @heads=split(/\s+/,$_);
			$heads[1]=~s/SN://;
			if(defined $hash{$heads[1]}) {
				print;
			}
		}
		else { 
			print;	#other header, always print
		}
	}
	else {
		my @tab = split(/\s+/, $_);
		if(defined $hash{$tab[2]}){	#else don't print at all
		
			
			if($tab[6] eq "=") {
				print;
			}
			else {
				if(defined $hash{$tab[6]}) {
					print;
				}
				else {
					$tab[6]="=";
					$tab[1]+=8;
					$tab[7]=$tab[3];
					print join("\t", @tab)."\n";
					$badmatecnt++;
				}
			}
		}
		else {
			$badreadcnt++;
		}		
		$totCnt++;	
	}
}
close(SAM);
print STDERR "$totCnt reads in total; $badreadcnt reads removed, and $badmatecnt were mate fixed.\n";
$time = time - $time;
print STDERR "Time elapsed: $time sec.\n";
