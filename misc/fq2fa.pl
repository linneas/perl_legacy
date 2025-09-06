#!/usr/bin/perl


# # # # # #
# fq2fa.pl
# written by Linnéa Smeds                     June 2011
# =====================================================
# Change files in fastq format to fasta format
# =====================================================
# Usage: fq2fa.pl <seqfile.fq> <seqfile.fa>
#
# Example: fq2fa.fa seq.fastq seq.fa

use strict;
use warnings;

# Input parameters
my $inFq = $ARGV[0];
my $outFa = $ARGV[1];


open(IN, $inFq);
open(OUT, ">$outFa");

while(<IN>) {
	if($_ =~ m/^@/) {
		my $head = $_;
		$head=~s/@/>/;

		print OUT $head;

		my $next = <IN>;
		while ($next !~ m/^\+/) {
			print OUT $next;
			$next=<IN>;
		}
	}
}
