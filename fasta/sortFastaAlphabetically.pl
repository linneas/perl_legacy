#!/usr/bin/perl

# # # # # #
# sortFastaAlphabetially.pl           
# written by Linnéa Smeds                    28 April 2014
# ========================================================
# Takes a fasta file and sort the entries alphabetically.
# If there are several sequences with exactly the same
# name, all but the first are given extensions 1,2,3 etc.
# ========================================================
# usage perl sortFastaAlphabetially.pl fasta.fa >sorted.fa 

use strict;
use warnings;

my $in = $ARGV[0];


# Save all sequences in hash
my %seqHash = ();
open(IN, $in);
my $cnt=1;
while(<IN>) {

	if($_ =~ m/^>/){
		my @tab = split(/\s+/, $_);
		my $head = $tab[0];
		$head =~ s/>//;
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
		unless(eof(IN)) {
			seek(IN, -length($next), 1);
		}

		if(defined $seqHash{$head}) {
			$head=$head.$cnt;
			$cnt++;
		}
		else {
			$cnt=1;
		}

		$seqHash{$head} = $seq;
	}
}
close(IN);


# Go through hash and print
foreach my $key (sort {$a cmp $b} keys %seqHash) {
	
	print ">$key\n";

	my @blocks = split(/(.{80})/i, $seqHash{$key});
	foreach my $bl (@blocks) {
		if($bl ne "") {
			print "$bl\n";
		}
	}
	$cnt++;	
}

