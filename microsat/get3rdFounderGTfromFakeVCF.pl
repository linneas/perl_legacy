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
my $VCF=$ARGV[0];	# 3+4+N columns: chr pos, motif, + 4 known haplotypes (A,B,C,D) 
					# + any number of offspring genotypes
my $F1=$ARGV[1];	# Column(s) of the known F1s, separated with "," (1-based)
my $OUT = $ARGV[2];	# Filtered fake VCF file


# Open outfile handle
open(OUT, ">$OUT");

my $header;

print "Go through VCF like file...\n";
my ($cnt, $savecnt)=(0,0);
open(IN, $VCF);
while(<IN>) {
	if(/^#/) {
		$header=$_;
		chomp($header);
		print OUT $header."\tFOUNDER3\n";
	}
	else {
		my @t = split(/\s+/, $_); 	
 		my ($a,$b,$c,$d)=($t[3],$t[4],$t[5],$t[6]);
		my %Known=($a=>"A", $b=>"B", $c=>"C", $d=>"D");
		my %Founder3=();		

		# Go through each individual and phase the F1s if possible, and also print
		# the 3rd founders genotypes (if possible)
		my @F = split(/,/, $F1);
		foreach my $f (@F) {
			my $f1pos=$f-1;
			if($t[$f1pos] ne ".") {
				my ($a1,$a2);
				if($t[$f1pos] =~ m/\//) {
					($a1,$a2)=split(/\//, $t[$f1pos]);
				}
				else {
					($a1, $a2)=($t[$f1pos],$t[$f1pos]);
				}

				# If the first allele is found among A-D
				if(defined $Known{$a1}) {
					# the second allele is also found (and is not the same)
					# =>We know Founder3 has either of those, but not which one
					if(defined $Known{$a2} && $Known{$a2} ne $Known{$a1}) {
						unless(defined $Founder3{$a1}) {
							$Founder3{$a1}="UNCERT";
						}
						unless(defined $Founder3{$a2}){	
							$Founder3{$a2}="UNCERT";
						}
					}
					# if not, the second allele is for sure from Founder3
					else {
						$Founder3{$a2}="CERT";
						# Phase the F1:
						$t[$f1pos]=$a1."|".$a2;
					}
				}
				# If not, check the second allele
				elsif(defined $Known{$a2}) {
					# Already know that the first allele isn't found
					$Founder3{$a1}="CERT";
					# Phase the F1:
					$t[$f1pos]=$a2."|".$a1;
				}	
				# If none of the alleles match, something is wrong!
				else {
					print STDERR "ERROR: F1 in col $f doesn't match Founders! Line: $_"; 
					$t[$f1pos].="(!)";
				}
			}
		}

		# Check if any haplotypes were saved, and if so print them as a last column
		my (@newCert,@newUnc);
		for my $key (keys %Founder3) {
			if($Founder3{$key} eq "UNCERT")	{
				push @newUnc, $key;
			}
			else {
				push @newCert, $key;
			}
		}
		if(scalar(@newCert)>2){
			print STDERR "ERROR: >2 alleles assigned to Founder3! Line: $_";
		}
		else {
			my $newGT= join(",", @newCert).";".join("or", @newUnc);
			print OUT join("\t", @t)."\t".$newGT."\n";
		}

		$cnt++;
	}
		
		
}
close(IN); 
print "...Processed $cnt lines\n";


$time=time-$time;
print "Total time elapsed: $time sec\n";
