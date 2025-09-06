#!/usr/bin/perl

# combineFastaFilesSort.pl
# written by Linnéa Smeds                       Nov 2011
# ======================================================
# Takes any number of fasta files and combines them into 
# one with all the fasta entries sorted alphabetically.
# ======================================================


use strict;
use warnings;

my %hash = ();

foreach my $file (@ARGV) {
	open(IN, $file);
	while(<IN>) {
		if($_ =~ m/^>/) {
	
			my $head = $_;
			my $seq = "";
	
			my $next = <IN>;
			while ($next !~ m/^>/) {
				$seq .= $next;
				if(eof(IN)) {
					last;
				}	
				$next = <IN>;
			}
			seek(IN, -length($next), 1);

			$hash{$head} = $seq;
		}
	}
}
close(IN);

foreach my $key (sort keys %hash) {
	print $key.$hash{$key};
}

