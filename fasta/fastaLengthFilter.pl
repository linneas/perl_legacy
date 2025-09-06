#!/usr/bin/perl

# # # # # # 
# FastaLengthFilter.pl	 	      written by LS 2010-06-16
# ========================================================
# Takes a fasta file and saves only the sequences that are
# longer than a given length threshold.
# ========================================================
# usage perl 

use strict;
use warnings;

my $in = $ARGV[0];
my $thres = $ARGV[1];
my $output = $ARGV[2];

my $time = time;

open(IN, $in);
open(OUT, ">$output");

while(<IN>) {
	
	if($_ =~ m/^>/) {
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

		if(length($seq)>=$thres) {
			print OUT $head;

			my @blocks = split(/(.{80})/i, $seq);
			foreach my $b (@blocks) {
				if($b ne "") {
					print OUT "$b\n";
				}
			}
		}
	}
}
close(IN);

$time = time - $time;
print "Time elapsed: $time sec.\n";
