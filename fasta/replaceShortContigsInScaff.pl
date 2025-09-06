#!/usr/bin/perl

my $usage = "
# # # # # #
# replaceShortContigsInScaff.pl
# written by Linnéa Smeds                     4 Mar 2014
# ======================================================
# Replace stretches of AGCT (=non-N) shorter than some
# threshold with Ns (useful for preprocessing before
# splitting assembly and submitting to NCBI.
# Note: The threshold 200 will keep scaffolds that are
# 200bp long, but remove those that are 199 and shorter.
# Note2: This script allows for 1 N inside non-N regions
# (also allowed by NCBI, not as gap but as ambiguous bp)
# but this can be changed by setting the parameter minN
# to one instead of two (hardcoded in script).
# ======================================================
# Usage: perl replaceShortContigsInScaff.pl <file.fasta> \
#			<threshold> <newfile.fasta>
";

use strict;
use warnings;

# Input parameters
my $FASTA = $ARGV[0]; 
my $THRES = $ARGV[1];
my $OUT = $ARGV[2];

# Other parameters
my $rowlength = 100;
my $minN=2;
my $time = time;

# Open output file
open(OUT, ">$OUT");

my ($conv_n, $conv_bp, $rm_n, $rm_bp, $scafcnt, $emptyscaf)=(0, 0, 0, 0, 0, 0);

open(IN, $FASTA);
while(<IN>) {
	if($_ =~ m/^>/){
		my $line = $_;

		# Save the sequence (ignore blanks)
		my $seq = "";
		my $next = <IN>;
		while ($next !~ m/^>/) {
			chomp($next),
			$seq.= $next;
			if(eof(IN)) {
				last;
			}	
			$next = <IN>;
		}
		seek(IN, -length($next), 1);


		# Splitting the sequence on NN or more, and replace short seq with N
		my $newSeq = "";
		my @seqs = split(/([nN]{$minN,})/, $seq);
		for(my $i=0; $i<scalar(@seqs); $i++) {

			# Looking at non N regions: 
			unless($seqs[$i] =~ m/N/i) {
				# If the region is shorter than the threshold
				if(length($seqs[$i])<$THRES) {
				
					$conv_n++;
					$conv_bp+=length($seqs[$i]);
					$seqs[$i]="N" x length($seqs[$i]);
				}
			}

			# Add the sequence back again (changed or not)	
			$newSeq.=$seqs[$i];
		}
		$scafcnt++;

		# Check that the new sequence doesn't start or end with N
		if($newSeq=~m/(^[Nn]+)/) {
			$newSeq=~s/(^[Nn]+)//;
			$rm_n++;
			$rm_bp+=length($1)
		}
		if($newSeq=~m/([Nn]+$)/) {
			$newSeq=~s/([Nn]+$)//;
			$rm_n++;
			$rm_bp+=length($1)
		}
		
	
		# Print the altered sequence (if it's non empty)
		if(length($newSeq)==0) {
			print "Scaffold removed completely: $line";
			$emptyscaf++;
		}
		else {
			my @seqParts = split(/(.{$rowlength})/, $newSeq);
			print OUT $line;
			for my $seqs (@seqParts) {
				unless($seqs eq "") {
					print OUT $seqs."\n";
				}
			}
		}
	}
}

$time = time - $time;
print "\n---------- Summary $FASTA ----------\n";
print "Converted $conv_n short regions ($conv_bp bp) to Ns\n";
print "Removed $rm_n short regions ($rm_bp bp) from beginning or end of scaffolds\n"; 
print "Scaffolds processed: $scafcnt ($emptyscaf was removed completely)\n";
print "Total time elapsed: $time sec\n";
my $fn = length($FASTA)+30;
my $footer = "-" x $fn;
print $footer."\n";
