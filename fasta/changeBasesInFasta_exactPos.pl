#!/usr/bin/perl

# changeBasesInFasta.pl
# written by Linnéa Smeds                      14 Juni 2013
# Modifyed to only change base (not remove or insert!)
# Now takes a VCF file for changes!!!
# =========================================================
# Takes a fasta and a vcf file:
#
# The vcf should have the format:
# Name	Pos	col	Base	Newbase	[other col]
# For example:
# scaf1	140	.	A	C	....
# scaf1	201	.	G	T	...
#
# NOTE: 1-based positions!!!!
# =========================================================


use strict;
use warnings;

# Input parameters
my $FASTA = $ARGV[0];
my $VCF = $ARGV[1];
my $OUTPUT = $ARGV[2];

open(OUT, ">$OUTPUT");

my $change_cnt = 0;

# Go through the fasta (may include several sequences)
open(IN, $FASTA);
while(<IN>) {
	if($_ =~ m/^>/) {
		my $head = $_;
		my $seq = "";
		chomp($head);
		$head=~s/>//;
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

		# Sequence is saved in array with one base per index
		my @seqs = split("", $seq);
	
#		print "Saved ".scalar(@seqs)." in sequence array for $head\n";

		# Go through the list
		open(LIST, $VCF);
		while(my $list=<LIST>) {
			chomp($list);
			my @col=split(/\t/, $list);

			# Only look at rows where the sequence name matches
			if($head eq $col[0]) {
				my $pos=$col[1]-1;
				
				# Single change
				unless($seqs[$pos] eq $col[3]) {
					print "ERROR CHANGE: $head at ".$col[1].", listed as ".$col[3]." but is ".$seqs[$pos]."\n";
				}
				$seqs[$pos]=$col[4];
				$change_cnt++;
			}
		}
		close(LIST);

		my $newseq = join("", @seqs);
		my @blocks = split(/(.{80})/i, $newseq);
		print OUT ">".$head."\n";
		foreach my $b (@blocks) {
			if($b ne "") {
				print OUT "$b\n";
			}
		}

	}
}
close(IN);
close(OUT);

print "$change_cnt bases were changed.\n";
