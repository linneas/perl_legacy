#!/usr/bin/perl

# findPotMutPedigree_F1.pl  	
# written by Linnéa Smeds,                  13 Feb 2015
# Partly based on Axel Einarsson's script f1PotMut.py
# =====================================================
# Takes a VCF file (preferibly cleaned and masked) and
# find potential denovo mutations in a F1 individual
# with known parents and offspring.
#
# This is a modified version that doesn't care about the
# genotypes of the offspring.
#
# =====================================================
# usage 


use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0];	# The vcf file with all positions
my $CONTROL = $ARGV[1]; # Controlfile, with all concerned individuals listed
my $MINCOV = $ARGV[2];	# Minimum coverage, must be true for all individuals in trio

my $ALLRAT=0.25;	#This is the allele ratio. Even if called, we want it to be present in this fraction of reads

my $IND = "";
my @PARENT = ();
my @OFFSPRING = ();
my @OTHER = ();

# Save the individuals
open(IN, $CONTROL);
while(<IN>) {
	my @tab=split(/\s+/, $_);
	if($tab[1] eq "IND") {
		$IND=$tab[0];
#		print "IND is $IND\n";
	}
	elsif($tab[1] eq "PARENT") {
		push @PARENT, $tab[0];
#		print "PARENT is ".$tab[0]."\n";

	}
	elsif($tab[1] eq "OFFSPRING") {
		push @OFFSPRING, $tab[0];
	}
	elsif($tab[1] eq "OTHER") {
		push @OTHER, $tab[0];
	}
}
close(IN);

# Go through vcf 
my %indcol = ();
open(VCF, $VCFFILE);
while(<VCF>) {
	if(/^##/){
#		print;
	}
	elsif(/^#CHROM/) {
		my @tab=split(/\s+/, $_);
		for (my $i=9; $i<scalar(@tab); $i++) {
			$indcol{$tab[$i]}=$i;
		}
	}
	else {
		my $printflag="off";
		my @tab=split(/\s+/, $_);
		

		# First, looking at individual (we only consider sites where ind is "0/1")
		my @it=split(/:/, $tab[$indcol{$IND}]);
		
		if($it[0] eq "./." || $it[0] ne "0/1" || $it[2]<$MINCOV) {
			next;
		}
		else {
			my ($ad1,$ad2) = split(/,/, $it[1]);

			# Checking that the allele is present in a sufficient fraction of the reads
			# But first check that there are any reads at all...
			if($ad1+$ad2==0) {
				print "Something is wrong on line $_";
				next;
			}
			if($ad2/($ad1+$ad2)<$ALLRAT) {
				next;
			}
			# Checking that the likelihood for the other GT is not also 0 (if so, we
			# can't be sure it's really heterozygous)
			my @li=split(/,/, $it[scalar(@it)-1]);
			if($li[0] == 0 || $li[2] == 0) {
				next;
			}
			
		} 

		# Looking at the parents; they need to be homozygous and have sufficient cov
		# Also, the likelihood score should not be "0" for two GT (meaning both are
		# equally likely)
		my @p1=split(/:/, $tab[$indcol{$PARENT[0]}]);
		my @p2=split(/:/, $tab[$indcol{$PARENT[1]}]);
		if($p1[0] eq "0/0" && $p1[2]>=$MINCOV && $p2[0] eq "0/0" && $p2[2]>=$MINCOV) {	
			my @l1=split(/,/, $p1[scalar(@p1)-1]);
			my @l2=split(/,/, $p2[scalar(@p2)-1]);
			unless($l1[1] == 0 || $l2[1] == 0) {
				$printflag="on";
			}
		}
		else {
			next;
		}
		
		# THIS VERSION OF THE SCRIPT DOESNT CARE ABOUT OFFSPRING GT!
		# Looking at the offspring (no coverage thres so far)
#		my $has_it=0;
#		my $alt_homo=0;
#		for my $off (@OFFSPRING) {
#			my @o=split(/:/, $tab[$indcol{$off}]);
#			if($o[0] eq "0/1") {	
#				$has_it++;
#			}
#			if($o[0] eq "1/1") {
#				$alt_homo++;
#			}
#		}
#		if($has_it==0 || $alt_homo>0) {
#			next;
#		}

		# Looking at the other individuals (none can have the GT)
		my $has_it=0;
		for my $oth (@OTHER) {
			my @o=split(/:/, $tab[$indcol{$oth}]);
			if($o[0] eq "0/1" || $o[0] eq "1/1") {	
				$has_it++;
			}
		}
		if($has_it>0) {
			next;
		}

		# Check how many that are left:
		if($printflag eq "on") {
			print;
		}

			

	}
}
close(VCF);	
