#!/usr/bin/perl

# findPotMutPedigree_F1.pl  	
# written by Linnéa Smeds,                  13 Feb 2015
# =====================================================
# Takes a VCF file and an mpileup file for the same sites
# and an arbitrary number of individuals, and prints the
# number of alternate alleles for each individual.
# =====================================================
# usage 


use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0]; # The vcf file with all potential positions
my $PILEUP = $ARGV[1];  # Excerpt from a samtools mpileup file, with SCAF, POS, BASES_IND1 [BASES_IND2 etc]
my $OUTPUT = $ARGV[2];	# prefix for the output files

open(OUT, ">$OUTPUT");

# GO THROUGH THE TWO FILES SIMULTANEOUSLY
my ($badparent, $okparent, $badind)=(0,0,0);
open(VCF, $VCFFILE);
open(PILE, $PILEUP);
while(<VCF>) {
	unless(/^#/){
		my $pline=<PILE>;
		my @v=split(/\s+/, $_);
		my @p=split(/\s+/, $pline);
		my $ref=$v[3];
		my $alt=$v[4];
		
		# Check number of columns to find no of ind
		my $maxcol=scalar(@p);
		$maxcol--;

	#    print $v[0]."\t".$v[1]."\t".$p[0]."\t".$p[1]."\n";
		unless($v[0] eq $p[0] && $v[1] eq $p[1]) {
		    print "something is wrong with lines:\n";
		    print "\t$_";
		    print "\t$pline\n";
		    die;
		}
		
		print OUT $v[0]."\t".$v[1];
		
		# Go through each ind, and remove non base characters and indels
		for(my $i=2; $i<=$maxcol; $i++) {  
		    $p[$i]=~ s/\^.//g; 	# Removing "start of read" + qual char
		    $p[$i]=~ s/\$//g;	#Removing "end of read" char

			while($p[$i]=~m/[+-](\d+)/) {
				my $indel=$1;
				$p[$i]=~s/[+-]\d+[ATCGNatcgn]{$indel}//;
		    }
		    
		    # Make string upper case for matching
		    $p[$i]=uc($p[$i]);  
		    
		    # Go through the characters
		    my @char=split(//, $p[$i]); 
		    my $altno=0;       
		    foreach my $c (@char) {
		    	if($c eq $alt) {
		    		$altno++;
		    	}
		    }
		    print OUT "\t".$altno;
		       
		}
		print OUT "\n";
     }
}
close(VCF);
close(PILE);
close(OUT);

   
