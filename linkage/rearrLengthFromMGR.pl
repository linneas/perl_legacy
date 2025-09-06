#!/usr/bin/perl


# # # # # #
# rearrLengthFromMGR.pl
# written by Linnéa Smeds                    Jan 2013
# ===================================================
# Takes a list of chromosomes, and for each chrom if
# finds the mgr-file and search for lines describing
# rearrangements for a certain species (Give the sp
# number as input). The lines give the blocks that are
# involved  and check which blocks involved
# in each rearrangement - then get the sum of the 
# block lengths from the block file.
# NOTE - the mgr file must be for a single chromosome
# since there are no chr info in a concatenated mgr.
# ===================================================
# Usage: 

use strict;
use warnings;
use List::Util qw(max min);


# Input parameters
my $CHROMLIST = $ARGV[0];
my $SP_NO = $ARGV[1];	#Depending on how sp are sorted,
			#right now: fa=0, tg=1, gg=2
my $OUTPREF = $ARGV[2];

# Output files
my $SUMMARY = $OUTPREF.".rearrLengths.txt";
open(OUT, ">$SUMMARY");
my $REARRLIST = $OUTPREF.".rearrList.txt";
open(OUT2, ">$REARRLIST");
print OUT2 "#CHR	ID	START	STOP	LENGTH	BLOCK_AFTER_CHANGE\n";
my $FRAC = $OUTPREF.".fracRearr.txt";
open(OUT3, ">$FRAC");
print OUT3 "#CHR	ALL_BLOCKS	REARR_BLOCKS\n";

#Go through the chromosomesone by one
open(CHR, $CHROMLIST);
while(my $chrom = <CHR>) {
	chomp($chrom);
	
	my $blockfile = "blocks_".$chrom."/blocks.txt";
	my $mgrfile = $chrom.".mgr";

	#save blocks in hash
	unless(-e $blockfile){
		die "There are no blockfile named $blockfile.\n";
	} 
	my %blocks = ();
	open(BL, $blockfile);
	while(<BL>) {
		unless(/#/) {
			my @t = split(/\s+/, $_);
			my $startcol = 4*$SP_NO+2;
			my $lencol = 4*$SP_NO+3;
			my $idcol = 4*$SP_NO+1;
			$blocks{$t[0]}{'start'}=$t[$startcol];
			$blocks{$t[0]}{'len'}=$t[$lencol];
			$blocks{$t[0]}{'id'}=$t[$idcol];
#			print "DEBUG: add ".$t[0]." with start ".$blocks{$t[0]}{'start'}." and end ".$blocks{$t[0]}{'len'}."\n";
		}
	}
	close(BL);

	my %usedBlocks = ();
	# Go through MGR file and search for "in $SP_NO do []"
	open(IN, $mgrfile);
	while(<IN>) {
		#Found the rearrangment line!
		if(/^in $SP_NO do reversal/) {
			
			
			my @t = split(/\s+/, $_);
			my ($from, $to) = ($t[5], $t[7]); 
			my ($startpos, $endpos);

			#Check signs
			#From block:
			if($from =~ m/-/) {
				$from =~ s/-//;
				$startpos = $blocks{$from}{'start'}+$blocks{$from}{'len'}-1;
			}
			else {
				$startpos = $blocks{$from}{'start'};
			}
			#To block:
			if($to =~ m/-/) {
				$to =~ s/-//;
				$endpos = $blocks{$to}{'start'}
			}
			else {
				$endpos = $blocks{$to}{'start'}+$blocks{$to}{'len'}-1;
			}

			#Print the start positions
			print OUT2 $chrom."\t".$blocks{$from}{'id'}."\t".$startpos."\t".$endpos."\t";

		
#			print "DEBUG: Line is $_";

			my $concat = "";
			
			#Need to find the right "fasta header" with following block order
			if($SP_NO == 0) {		##Flycatcher
				my $head = <IN>;
#				print "DEBUG: looking at $head";
				my $next = <IN>;
				while ($next =~ m/\$/) {

					chomp($next);
					$concat = $concat." ".$next;
					$next = <IN>;
				}
			}
			elsif($SP_NO == 1) {	##Zebra finch
				<IN>;	#flycatcher header
				my $next = <IN>;
				while ($next =~ m/\$/) {
		#			print "inside first zf while with line $next";
					$next = <IN>;	#flycatcher blocks
					
				}
				my $head = $next;
				$next = <IN>;
				while ($next =~ m/\$/) {
					chomp($next);
					$concat = $concat." ".$next;
					$next = <IN>;
				}
			}
			elsif($SP_NO == 2) {		##Chicken
				<IN>;	#flycatcher header
				my $next = <IN>;
				while ($next =~ m/\$/) {
					$next = <IN>;	#flycatcher blocks
				}
				my $head = $next;	#zf header
				$next = <IN>;
				while ($next =~ m/\$/) {
					$next = <IN>;	#zf blocks
				}
				$head = $next;
				$next = <IN>;
				while ($next =~ m/\$/) {
					chomp($next);
					$concat = $concat." ".$next;
					$next = <IN>;
				}
			}
#			print "DEBUG: with blocks: $concat\n";


			# Go trough all blocks and save the relevant 
			# NOTE that they already are inversed here!
			my @b = split(/\s+/, $concat);
			my $flag = "off";
			my $sum = 0;
			my $blockstring = "";		#This is gonna be backwards..
			foreach my $bl (@b) {
				my $blsign = $bl;		#Save potential minus sign
				$bl =~s/-//;

				if($flag eq "on") {
					$sum+=$blocks{$bl}{'len'};
					$blockstring .= "|".$blsign;
					$usedBlocks{$bl}=1;
				}
				if($bl eq $to) {		# the line is already flipped, so to basically means "from"	
					unless(defined $blocks{$bl}{'len'}) {
						print "Looking at $_\n";
					} 
					$sum+=$blocks{$bl}{'len'};
					$flag="on";
					$blockstring=$blsign;
					$usedBlocks{$bl}=1;
				}
				if($bl eq $from) {		#same here, this means "to"
					$flag = "off";
				}
			}

			print OUT $chrom."\t".$sum."\n";
			print OUT2 $sum."\t".$blockstring."\n";

		}		
	}
	my $involved = 0;
	my $all = 0;
	foreach my $key (keys %blocks) {
		$all+=$blocks{$key}{'len'};
		if(defined $usedBlocks{$key}) {
			$involved+=$blocks{$key}{'len'};
		}
	}
	print OUT3 $chrom."\t".$all."\t".$involved."\n";
}
close(CHR);
close(OUT);	
close(OUT2);
	
