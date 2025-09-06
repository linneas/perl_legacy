#!/usr/bin/perl

# formatFastaFile_seq2stdoute.pl
# written by Linnéa Smeds                       August 2011
# Modified to print to standard output 4 Dec 2014
# =========================================================
# Takes a fasta file and removes blank lines and prints the
# sequences with a certain number of letters on each row.
# Problem: when fasta is input from pipe, only every second 
# sequence is printed... (why??) 
# =========================================================


use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0];
my $bpPerRow = $ARGV[1];

my ($seq,$head) = ("","");
open(IN, $fasta);
my $scaffCnt = 0;
while(<IN>) {

	if(/>/) {
		chomp($_);
		$scaffCnt++;
		my $head = $_;
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

		print $head."\n";

		my @blocks = split(/(.{$bpPerRow})/i, $seq);
		foreach my $b (@blocks) {
			if($b ne "") {
				print "$b\n";
			}
		}
	}
}
close(IN);

print STDERR "Formatted $scaffCnt sequences.\n";

