#!/usr/bin/perl

# formatFastaFile.pl
# written by Linnéa Smeds                       August 2011
# =========================================================
# Takes a fasta file and removes blank lines and prints the
# sequences with a certain number of letters on each row.
# =========================================================


use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0];
my $bpPerRow = $ARGV[1];
my $output = $ARGV[2];

my ($seq,$head) = ("","");
open(IN, $fasta);
open(OUT, ">$output");
my $scaffCnt = 0;
while(<IN>) {
	if($_ =~ m/^>/) {
		chomp($_);
		$scaffCnt++;
		my $head = $_;
		my $seq = ();
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

		print OUT $head."\n";

		my @blocks = split(/(.{$bpPerRow})/i, $seq);
		foreach my $b (@blocks) {
			if($b ne "") {
				print OUT "$b\n";
			}
		}
	}
}
close(IN);
close(OUT);

print "Formatted $scaffCnt sequences.\n";

