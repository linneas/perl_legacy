#!/usr/bin/perl

# # # # # #
# reverseComplement.pl
# written by Linnéa Smeds 20 oct 2010
# MOD 22/10-2014 TO TAKE A SEQUENCE FROM THE STREAM 
# (LIKE A PIPE) WITHOUT HEADER, ANDPRINT DIRECTLY TO 
# STANDARD OUTPUT
# ====================================================
# 
# ====================================================
# Usage: perl

use strict;
use warnings;

#Input
my $in = $ARGV[0];

open(IN, $in);

while(<IN>) {
	
	my $seq="";
	my $next = $_;
	while ($next !~ m/^>/) {
		chomp($next),
		$seq.= $next;
		if(eof(IN)) {
			last;
		}	
		$next = <IN>;
	}
	seek(IN, -length($next), 1);
	$seq = &reverse($seq);
	my @blocks = split(/(.{80})/i, $seq);
	foreach my $b (@blocks) {
		if($b ne "") {
			print "$b\n";
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
