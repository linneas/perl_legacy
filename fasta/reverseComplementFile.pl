#!/usr/bin/perl

# # # # # #
# reverseComplement.pl
# written by Linnéa Smeds 20 oct 2010
# ====================================================
# 
# ====================================================
# Usage: perl

use strict;
use warnings;

#Input
my $in = $ARGV[0];
my $output = $ARGV[1];

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
		chomp($head);
		print OUT $head ."\tREV\n";
		$seq = &reverse($seq);
		my @blocks = split(/(.{80})/i, $seq);
			foreach my $b (@blocks) {
				if($b ne "") {
					print OUT "$b\n";
				}
			}
	}
}

sub reverse { 
	my $DNAstring = shift;

	my $output = "";

	my @a = split(//, $DNAstring);

	for(@a) {
		$_ =~ tr/[A,T,C,G,a,t,c,g]/[T,A,G,C,t,a,g,c]/;
		$output = $_ . $output;
	}

	return $output;
}
