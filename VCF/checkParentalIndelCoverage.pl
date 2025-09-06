#!/usr/bin/perl

# checkParentalIndelCoverage.pl  	
# written by Linnéa Smeds,                  13 Feb 2015
# Based on checkParentalSNPCoverage.pl
# =====================================================
# Takes a VCF file (preferibly cleaned and masked) and
# a mpileup-file with the parents and checks a) that
# the alt variant is present in the individual and b)
# that it's NOT present in the parents.
# =====================================================
# usage 


use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0]; # The vcf file with all potential positions
my $PILEUP = $ARGV[1];  # Excerpt from a samtools mpileup file, with SCAF, POS, BASES_P1 BASES_P2, BASES_INS
my $PREFIX = $ARGV[2];	# prefix for the output files

# Two output files, one for passed SNPs and one for failed
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

#	print "DEBUG: looking at ".$v[0].":".$v[1]."\n";
#    print $v[0]."\t".$v[1]."\t".$p[0]."\t".$p[1]."\n";
    unless($v[0] eq $p[0] && $v[1] eq $p[1]) {
        print "something is wrong with lines:\n";
        print "\t$_";
        print "\t$pline\n";
        die;
    }
    
    my ($altmom, $altdad, $altind) = (0,0,0);
    
    # IF WE HAVE AN INSERTION:
    if(length($alt)>1){
    	my $ins=$alt;
#    	print "\tIns is now $ins, and then changed to:\n";
    	my @i=split(//, $ins);
    	shift @i;
    	$ins=join('',@i);
    	## TRIED THIS BUT IT DIDN'T WORK: $ins = s/^.//; 	
#    	print "\t$ins\n";
    	
    	my $len=length($ins);
    	
    	# check if ind matches insertion
        if($p[4] =~ m/\+$len$ins/i) {
        	$altind++;
#        	print "\tInd has the insertion! (".$p[4].")\n";
        }
        #check if parents match insertion
       if($p[2] =~ m/\+$len$ins/i) {
        	$altmom++;
#        	print "\tMother has the insertion! (".$p[2].")\n";

        }
       if($p[3] =~ m/\+$len$ins/i) {
        	$altdad++;
#               	print "\tFather has the insertion! (".$p[3].")\n";

        }
	}
	# DELETION
	else{
		my $del=$ref;
#		print "\tDel is now $del, and then changed to:\n";
		my @d=split(//, $del);
    	shift @d;
    	$del=join('',@d);
 #   	print "\t$del\n";

		my $len=length($del);
		
		# check if ind matches deletion
        if($p[4] =~ m/\-$len$del/i) {
        	$altind++;
#        	print "\tInd has the deletion! (".$p[4].")\n";
        }
        #check if parents match deletion
       if($p[2] =~ m/\-$len$del/i) {
        	$altmom++;
#        	print "\tMother has the deletion! (".$p[2].")\n";
        }
       if($p[3] =~ m/\-$len$del/i) {
        	$altdad++;
#        	print "\tFather has the deletion! (".$p[3].")\n";
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






 
        
