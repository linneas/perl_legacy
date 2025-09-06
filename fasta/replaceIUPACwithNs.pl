#!/usr/bin/perl

# replaceIUPACwithNs.pl
# written by Linnéa Smeds                      16 Juni 2015
# =========================================================
# Takes a fasta file and mask all IUPAC characters (which
# can't be handled by all downstream software, for example
# lastz) with Ns. 
# =========================================================


use strict;
use warnings;

# Input parameters
my $FASTA = $ARGV[0];


# Go through the fasta (may include several sequences)
open(IN, $FASTA);
while(<IN>) {
	if($_ =~ m/^>/) {
		my $head = $_;
		my $seq  ="";
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
		
		$seq =~ s/[RYSWKMBDHV]/N/gi;
	
		my @blocks = split(/(.{80})/i, $seq);
		print $head;
		foreach my $b (@blocks) {
			if($b ne "") {
				print "$b\n";
			}
		}

	}
}
close(IN);

