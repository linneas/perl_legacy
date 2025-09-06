#!/usr/bin/perl

# # # # #
# splitVCFinScaffolds.pl        
# written by Linnéa Smeds 		     31 March 2014
# ========================================================
# Splits a VCF file into slighly overlapping outputfiles
# of a given window size (the overlap is hard-coded below,
# called "$ovlNo"). Output files are numbered 1,2,3,4 etc.
# ========================================================
# perl splitVCFinScaffolds.pl file.vcf some_suffix

use strict;
use warnings;

# Input parameters
my $VCF = $ARGV[0];		# input file of big vcf file
my $WIN = $ARGV[1];		# window size (the number of SNPs... 4000)
my $OUTSUFF = $ARGV[2];		# output file "some_suffix"

my $ovlNo=3;

# Loop over the VCF
my $header= "";			# vcf file header
open(VCF, $VCF);		# open input file
my $cnt=0;				# counter
my $last = "";			# last line
my $overlap = "";
my $totCnt = 1;
my $fileCnt =1;
while(<VCF>) {			
	if(/^#/) {			# if a line starts with "#", keep it as a vcf header
		$header.=$_;
	}			
	else {
		my @a = split(/\t/, $_);			# very 1st line of N00001 is split by tab
		if($cnt==0) {						# cnt==0 means 1st line when starting a new window,
			my $out=$a[0].".$fileCnt.".$OUTSUFF;		# output file name = 1st element of array @a = N00001, concatenated (.) with ".", "some_suffix"
			$fileCnt++;
			open(OUT, ">$out");				# open OUT as ">$out"
			print OUT $header;				# print header
			print OUT $overlap;				# print the lines that are saved in the overlap parameter
			print OUT $_;					# print 1st line
			unless($totCnt==1) {			# For all windows except the first, we want to  increase the counter with the number of overlaps+1
				$cnt=$ovlNo+1;
			}
			$cnt++;
			$overlap="";
#			print "DEBUG: save to file $out, cnt is now $cnt, line is $_\n";
		}
		else {
			if($cnt < $WIN) {				# if the 2nd line is the same with $last (say, N00001 again)
				print OUT $_;				# keep it and save it in OUT
#				print "DEBUG: cnt is $cnt and line is $_";
				if($WIN-$cnt<=$ovlNo) {		# If we are close to the end, we want to save the lines as overlaps
					$overlap.=$_;
#					print "DEBUG: cnt is $cnt, save overlap $_"; 
				}
				$cnt++;				
			}
			else {							# Outside of the window, save this line in overlap and start a new window next time you enter the loop
				close(OUT);					# close OUT (this is the previous file)
				$overlap.=$_;
#				print "DEBUG: outside of win, cnt is $cnt, line is $_";
				$cnt=0;
			  }
		}
		$totCnt++;							# increase the total counter
	}
}
close(OUT);


		

