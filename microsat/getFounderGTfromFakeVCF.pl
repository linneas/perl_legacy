#!/usr/bin/perl

# getFounderGTfromFakeVCF.pl  	
# written by Linnéa Smeds,                  14 Mar 2016
# =====================================================
# Takes a vcf like file with microsatellite lengths for
# a number of individuals, and information on which col
# the known founder and the F1s are in.
# Returns ....
# =====================================================
# usage: perl 

use strict;
use warnings;
use List::Util qw(min max);
my $time=time;


# Input parameters
my $VCF=$ARGV[0];	# 3+N columns: chr pos, reflen, + any number of genotypes
my $FOU1=$ARGV[1];	# Column of the known founder (1 based)
my $F1=$ARGV[2];	# Column(s) of the known F1s, separated with "," (1-based)
my $OUT = $ARGV[3];	# Filtered fake VCF file


# Open outfile handle
open(OUT, ">$OUT");


print "Go through VCF like file...\n";
my ($cnt, $savecnt)=(0,0);
open(IN, $VCF);
while(<IN>) {
	if(/^#/) {
		print OUT;
	}
	else {
		my @t = split(/\s+/, $_); 
		my $founderpos=$FOU1-1;
	
		#We only look at positions where Founder 1 is heterozygous
		if($t[$founderpos] =~ m/\//) {	
			my ($a, $b)=split(/\//, $t[$founderpos]);
			my %Founder2 = ();	
			my $FGT=min($a, $b)."/".max($a, $b);	#sort so we can compare
			my $F1concat="";
			my $badflag="off";
	
			if($a != $b) {	#Checking if heterozygous again (HipSTR+perl output gives homozygous as 32/32)

				# Go through all the F1s
				my @F = split(/,/, $F1);
				foreach my $f (@F) {
					my $f1pos=$f-1;
					if($t[$f1pos] ne ".") {
						my $fGT=min(split(/\//,$t[$f1pos]))."/".max(split(/\//,$t[$f1pos]));
						if($fGT eq $FGT){ #if F1 and Founder 1 are similar, the F1 is unformative)
							$F1concat.="\t.";
						}
						else {
							my ($v1,$v2);
					
							if($t[$f1pos] =~ m/\//){
								($v1,$v2)=split(/\//, $t[$f1pos]);
							}
							else {
								($v1,$v2)=($t[$f1pos],$t[$f1pos]);
							}

							# Sorting out the GTs:
							if($v1 eq $a || $v1 eq $b) {
								$Founder2{$v2}=1;
								$F1concat.="\t".$v1."|".$v2;
							}
							elsif($v2 eq $a || $v2 eq $b){
								$Founder2{$v1}=1;
								$F1concat.="\t".$v2."|".$v1;
							}
							else {
								print STDERR "Something is wrong, F1 (col $f) doesn't match Founder1: $_";
								$badflag="on";
							}
						}
					}
					else {
						$F1concat.="\t.";
					}
				}
			}
				

			# Check the hash, if there are exactly two variants (and no badflag) we're good:
			my $n=scalar keys %Founder2;
			if($n==2) {
				unless($badflag eq "on") {
					print OUT join("\t", @t)."\t".$a."\t".$b."\t".join("\t", (keys %Founder2)).$F1concat."\n";
					$savecnt++;
				}
			}
			elsif($n>2) {
				print STDERR "ERROR: MORE THAN 2 FOUNDER2 ALLELES SUPPORTED: $_";
			}
		}
	$cnt++;	
	}
}
close(IN); 
print "...Processed $cnt lines and saved $savecnt positions.\n";


$time=time-$time;
print "Total time elapsed: $time sec\n";
