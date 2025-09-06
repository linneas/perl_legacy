#!/usr/bin/perl

my $usage="
# # # # # #
# summarizeCovBedFromChrFiles.pl
# written by Linnéa Smeds                   25 Jan 2017
# =====================================================
# Takes chr specific output from genomicCoverageBed
# (BEDTools) and a list of wanted chromosomes, and then
# merge all wanted chromosomes into a combined histogram.
 
#
# INPUT:
# 1) list of wanted chromosomes
# 2) prefix of BEDTools genomeCoverageBed files
# 3) suffix "      "            "           "
#
# The coverage files should be on the form:
	prefix.chr.suffix.coverage (or prefix.chr.coverage
	 if suffix is not given).
				 regions as the wig file)
# =====================================================
# USAGE: perl summarizeCovBedFromChrFiles.pl <chrlist> \
#			<prefix> [<suffix>]
# Example:	 perl summarizeCovBedFromChrFiles.pl autosomes.txt \
#			/path/Ind1
# (if coverage files are called /path/Ind1.chr*.genome)
";


use strict;
use warnings;
use List::Util qw[min max];
#use Statistics::Basic qw(:all nofill);

# Input parameters
my $CHRLIST = $ARGV[0];	# List of wanted chromosomes
my $PREFIX = $ARGV[1];	# Prefix of coverage files
my $OUTSUFF = $ARGV[2];	# output is called $PREFIX.$OUTSUFF.coverage
my $INSUFF = $ARGV[2];  # Optional suffix of coverage files



# Go through chromosomes
open(CHR, $CHRLIST);
while(<CHR>) {
	my $chr=$_;
	chomp($chr);

	my $covfile;
	if($INSUFF) {
		$covfile="$PREFIX.$chr.$INSUFF.coverage";
	}
	else {
		$covfile="$PREFIX.$chr.coverage";
	}


	open(COV, $covfile)

# Save positions
my %pos = ();
open(VCF, $VCFFILE);
while(<VCF>) {
	unless(/^#/) {
		my @F=split(/\t/,$_);

		if($WIGTYPE eq "single" && $F[0] ne $SCAFFOLD) {
			next;
		}
		 	
		# Check if any of the variants are longer than 1 bp (indels)
		# Or if the site is triallelic (like A,T - meaning no clear alt)
		my $use = 0; 
		if (length($F[3]) > 1 || length($F[4]) > 1){
			$use++;
		}
		# We don't want indel or multiple-allele sites, so save only if there are no indels		
		if ($use == 0){
			$pos{$F[0]}{$F[1]}{'ref'}=$F[3];
			$pos{$F[0]}{$F[1]}{'alt'}=$F[4];
		}
	}
}
close(VCF);

my %col = ('A'=>1, 'C'=>2, 'G'=>3, 'T'=>4);

# Go through the wig file 
open(IN, $WIGFILE);
<IN>; <IN>;	# Skip two header lines
while(<IN>) {
	my @F = split(/\s+/,$_);

	my ($ref, $alt, $third, $allerr, $tot) = (0,0,0,0,0);
	my $thirdbase="";
	
	if($WIGTYPE eq "single") { # Need to separate the two cases
		if(defined $pos{$SCAFFOLD}{$F[0]}) {
			$ref=$F[$col{$pos{$SCAFFOLD}{$F[0]}{'ref'}}];
			$alt=$F[$col{$pos{$SCAFFOLD}{$F[0]}{'alt'}}];
			my ($tempbig, $tempbigno)=("",-1);
			foreach my $key (keys %col) {
				 $tot+=$F[$col{$key}];
				unless ($key eq $pos{$SCAFFOLD}{$F[0]}{'ref'} || $key eq $pos{$SCAFFOLD}{$F[0]}{'alt'}) {
					$allerr+=$F[$col{$key}];
					if($F[$col{$key}]>$tempbigno) {
						$tempbigno=$F[$col{$key}];
						$tempbig=$key;
					}
				}
			}
			$third=$tempbigno;
			$thirdbase=$tempbig;

			my ($thirdrate,$errate)=("NA","NA");

			if($tot>0) {
				$thirdrate=$third/$tot;
			 	$errate=$allerr/$tot;
			}
	
			print OUT $SCAFFOLD."\t".$F[0]."\t".$ref."(".$pos{$SCAFFOLD}{$F[0]}{'ref'}.")\t".$alt."(".
					$pos{$SCAFFOLD}{$F[0]}{'alt'}.")\t".$third."(".$thirdbase.")\t".$tot."\t".
					$thirdrate."\t".$errate."\n";


		}

	}

	
}
close(IN);
















