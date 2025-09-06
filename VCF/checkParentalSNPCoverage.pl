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
my $VCFFILE = $ARGV[0]; # The vcf file with all potential positions
my $PILEUP = $ARGV[1];  # Excerpt from a samtools mpileup file, with SCAF, POS, BASES_P1 BASES_P2
my $PREFIX = $ARGV[2];	# prefix for the output files

# Two output files, one for passed SNPs and pne for failed
my $GOOD = $PREFIX.".parentsOK.vcf";
my $BAD = $PREFIX.".uncerPar.vcf";
open(GOOD, ">$GOOD");
open(BAD, ">$BAD");

# GO THROUGH THE TWO FILES SIMULTANEOUSLY
my ($badparent, $okparent, $badind)=(0,0,0);
open(VCF, $VCFFILE);
open(PILE, $PILEUP);
while(<VCF>) {
    my $pline=<PILE>;
    my @v=split(/\s+/, $_);
    my @p=split(/\s+/, $pline);
    my $ref=$v[3];
    my $alt=$v[4];

#    print $v[0]."\t".$v[1]."\t".$p[0]."\t".$p[1]."\n";
    unless($v[0] eq $p[0] && $v[1] eq $p[1]) {
        print "something is wrong with lines:\n";
        print "\t$_";
        print "\t$pline\n";
        die;
    }
    
    # Remove non base characters and indels
    for(my $i=2; $i<=4; $i++) {  
        $p[$i]=~ s/\^.//g; 	# Removing "start of read" + qual char
        $p[$i]=~ s/\$//g;	#Removing "end of read" char

		while($p[$i]=~m/[+-](\d+)/) {
			my $indel=$1;
			$p[$i]=~s/[+-]\d+[ATCGNatcgn]{$indel}//;
        }
        
        # And make string upper case for matching
        $p[$i]=uc($p[$i]);   
           
    }
     
    # Go through the parents
    my @pa1 = split(//, $p[2]);
    my @pa2 = split(//, $p[3]);
    
    my ($refdad, $altdad, $refmom, $altmom) = (0,0,0,0);
    
    foreach my $dad (@pa1) {
        if($dad eq $ref) {
            $refdad++;
        }
        elsif($dad eq $alt) {
            $altdad++;
        }
    }
    foreach my $mom (@pa2) {
        if($mom eq $ref) {
            $refmom++;
        }
        elsif($mom eq $alt) {
            $altmom++;
        }
    }
    
    # Go through the individual
    my @ind = split(//, $p[4]);
    my ($refind, $altind) = (0,0);
    foreach my $i (@ind) {
        if($i eq $ref) {
            $refind++;
        }
        elsif($i eq $alt) {
            $altind++;
        }
    }
    
    
    if($altdad == 0 && $altmom == 0) {
        if($altind==0) {
            print BAD $_;
            $badind++;
        }
        else {
            print GOOD $_;
        }
        $okparent++;
    }
    else {
        print BAD $_;
        $badparent++;
    }
}
close(VCF);
close(PILE);
close(GOOD);
close(BAD);

print "For $PREFIX:\n";
print "\t$badparent positions removed due to alt allele in the parents\n";
print "\t$badind positions (out of $okparent remaining) removed due to no alt allele in the individual\n";






 
        
