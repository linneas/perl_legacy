#!/usr/bin/perl

# # # # # #
# replacePolyACGT.pl
# written by Linnéa Smeds                     9 oct 2013
# ======================================================
# Replace stretches of homopolymers (of any base, not
# only C and G) that are longer than some given thres.
#
# NOTE! This script doesn't work properly when input 
# fasta file is piped from some other command, because 
# it use a syntax that put lines back in the stream and
# that only work when reading real files...
# ======================================================
# Usage: perl replacePolyACGT.pl file.fa 100 newfile.fa

use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0]; 
my $thres = $ARGV[1];
my $OUT = $ARGV[2];

# Other parameters
my $rowlength = 100;

my $time = time;

open(IN, $fasta);
open(OUT, ">$OUT");

while(<IN>) {
	if($_ =~ m/^>/){
		my @tab = split(/\s+/, $_);
		my $head = $tab[0];
		my $seq = "";
		my $scafsum = 0;
		my $Ns = 0;

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

		my $length = length($seq);

		
		# Replace poly As, Cs, Gs and Ts by N (of the same length)
		$seq =~ s/(A{$thres,})/"N" x length($1)/gei;
		$seq =~ s/(T{$thres,})/"N" x length($1)/gei;
		$seq =~ s/(G{$thres,})/"N" x length($1)/gei;
		$seq =~ s/(C{$thres,})/"N" x length($1)/gei;


		my @seqParts = split(/(.{$rowlength})/, $seq);
		print OUT $head."\n";
		for my $seqs (@seqParts) {
			unless($seqs eq "") {
				print OUT $seqs."\n";
			}
		}
	}
}
$time = time - $time;
print "Total time elapsed: $time sec\n";
