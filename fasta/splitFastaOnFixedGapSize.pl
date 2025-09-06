#!/usr/bin/perl

# splitFastaOnFixedGapSize.pl
# written by Linnéa Smeds                       16 Nov 2016
# =========================================================
# Split a fasta file at every gap of a certain given size.
# (useful for dividing superscaffolds into original scaffs).
# =========================================================


use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0];
my $fixedN = $ARGV[1];
my $minLen =$ARGV[2];
my $output = $ARGV[3];

print "splittning on N-regions of size $fixedN\n";

my ($seq,$head) = ("","");
open(IN, $fasta);
open(OUT, ">$output");
my ($scaffCnt,$newCnt, $shortCnt, $n) = (0,0,0,0);
while(<IN>) {
	if($_ =~ m/^>/) {
		if($seq ne "") {
			my @seqs = split(/[nN]{$fixedN}/, $seq);
			foreach my $s (@seqs) {
				if (length($s)>=$minLen) {
					my @blocks = split(/(.{100})/i, $s);
					print OUT $head."_".$n."\n";
					foreach my $b (@blocks) {
						if($b ne "") {
							print OUT "$b\n";
						}
		
					}
					$n++;
					$newCnt++;
				}
				else {
					$shortCnt++;
				}
			}
			$n=0;
		}
		my @tab = split(/\s+/, $_);
		$head = $tab[0];
	#	$head = $_;
	#	chomp($head);
		$seq="";
		$scaffCnt++;
	}
	else {
		chomp($_);
		$seq.=$_;
	}
}
my @seqs = split(/[nN]{$fixedN}/, $seq);
foreach my $s (@seqs) {
	if (length($s)>=$minLen) {
		my @blocks = split(/(.{100})/i, $s);
		print OUT $head."_".$n."\n";
		foreach my $b (@blocks) {
			if($b ne "") {
				print OUT "$b\n";
			}

		}
		$n++;
		$newCnt++;
	}
	else {
		$shortCnt++;
	}
}

print "$scaffCnt sequences in original file\n";
print "$shortCnt short sequences removed\n";
print "$newCnt sequences after splitting\n";

close(IN);
close(OUT);
