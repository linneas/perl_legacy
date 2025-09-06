#!/usr/bin/perl


# # # # # #
# reuseFromMGR.pl
# written by Linnéa Smeds                    Feb 2013
# ===================================================
# Takes a list of chromosomes, and for each chrom it
# finds the mgr-file and search for lines describing
# rearrangements for a certain species (Give the sp
# number as input). The lines give the blocks that are
# involved and check which blocks involved
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
my $ALLENDS = $OUTPREF.".reuse.txt";
open(OUT, ">$ALLENDS");
print OUT "#CHR	BLOCK_END	INVOLVED\n";
my $SUMMARY = $OUTPREF.".reuseSummary.txt";
open(OUT2, ">$SUMMARY");
print OUT2 "#CHR	NOT_USED	USED_ONCE	REUSED\n";

my %all_used = ();
my $chrcnt=1;
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
	my %sides = ();
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
			$sides{$t[0]."s"} = 0;
			$sides{$t[0]."e"} = 0;
		}
	}
	close(BL);

	my %usedBlocks = ();
	# Go through MGR file and search for "in $SP_NO do []"
	open(IN, $mgrfile);
	my ($sp0_concat, $sp1_concat, $sp2_concat);
	while(<IN>) {
		if(/>/) {

			# First species (collared flycatcher)
			my $sp0_head=$_;
			$sp0_concat = "";
			my $next = <IN>;
			while ($next =~ m/\$/) {

				chomp($next);
				$sp0_concat = $sp0_concat." ".$next;
				$next = <IN>;
			}
			# Second species (zebra finch)
			my $sp1_head = $next;
			$sp1_concat = "";
			$next = <IN>;
			while ($next =~ m/\$/) {

				chomp($next);
				$sp1_concat = $sp1_concat." ".$next;
				$next = <IN>;
			}
			# Third species (chicken)
			my $sp2_head = $next;
			$sp2_concat = "";
			$next = <IN>;
			while ($next =~ m/\$/) {

				chomp($next);
				$sp2_concat = $sp2_concat." ".$next;
				$next = <IN>;
			}
		}

		# Find rearrangement line:
		elsif(/^in $SP_NO do reversal/) {
		
			my @t = split(/\s+/, $_);
			my ($from, $to) = ($t[5], $t[7]); 
			my ($startpos, $endpos);

			my $concat;

			if($SP_NO == 0) {
				$concat = $sp0_concat;
			}
			elsif($SP_NO == 1) {
				$concat = $sp1_concat;
			}
			elsif($SP_NO == 2) {
				$concat = $sp2_concat;
			}

			my @b = split(/\s+/, $concat);
			my $flag = "off";
			my $sum = 0;

			for (my $i=0; $i<scalar(@b); $i++) {
				my $b_nosign = $b[$i];
				$b_nosign =~s/-//;

				#Checking involved ends before block
				if($b[$i] eq $from) {
					if($from =~ m/-/) {
						$sides{$b_nosign."e"}++;
					}
					else {
						$sides{$b_nosign."s"}++;
					}

					unless($i==0) {
						my $tempprev = $b[$i-1];
						$tempprev =~ s/-//;
						if($b[$i-1] =~ m/-/) {
							$sides{$tempprev."s"}++;
						}
						else {
							$sides{$tempprev."e"}++;
						}
					}
				}

				#Checking involved ends after block
				if($b[$i] eq $to) {
					if($to =~ m/-/) {
						$sides{$b_nosign."s"}++;
					}
					else {
						$sides{$b_nosign."e"}++;
					}

					unless($i==scalar(@b)-1 || $b[$i+1] eq "\$") {
						my $tempsuc = $b[$i+1];
						$tempsuc =~ s/-//;
						if($b[$i+1] =~ m/-/) {
							$sides{$tempsuc."e"}++;
						}
						else {
							$sides{$tempsuc."s"}++;
						}
					}
				}
			}
		}
	}
	close(IN);

	# Print each block end and the number of times it has been involved in rearr
	foreach my $key (sort keys %sides) {
		print OUT $chrom."\t".$key."\t".$sides{$key}."\n";
		if($sides{$key}==0) {
			$all_used{$chrom}{'none'}++;
		}
		elsif($sides{$key}==1) {
			$all_used{$chrom}{'once'}++;
		}
		else {
			$all_used{$chrom}{'reuse'}++;
		}
	}
	$all_used{$chrom}{'pos'}=$chrcnt;
	$chrcnt++;
}
close(CHR);

foreach my $key (sort {$all_used{$a}{'pos'}<=>$all_used{$b}{'pos'}} keys %all_used) {
	unless($all_used{$key}{'none'}) {
		$all_used{$key}{'none'}=0;
	}
	unless($all_used{$key}{'once'}) {
		$all_used{$key}{'once'}=0;
	}
	unless($all_used{$key}{'reuse'}) {
		$all_used{$key}{'reuse'}=0;
	}
	print OUT2 $key."\t".$all_used{$key}{'none'}."\t".$all_used{$key}{'once'}."\t".$all_used{$key}{'reuse'}."\n";

}



close(OUT);
close(OUT2);
