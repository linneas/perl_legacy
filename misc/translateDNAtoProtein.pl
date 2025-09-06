#!/usr/bin/perl

# translateDNAtoProtein.pl
# written by Linnéa Smeds                      October 2011
# =========================================================
# Takes a multiple fasta file and print the DNA sequences
# translated to proteins.
# =========================================================

use strict;
use warnings;
use Bio::SeqIO;

my $infile = $ARGV[0];
 
my $seqio_obj = Bio::SeqIO->new(-file =>$infile, -format => "fasta" );

while (my $seq_obj = $seqio_obj->next_seq){   
 	# print the sequence   
	my $prot=$seq_obj->translate;
	print ">",$prot->display_id,"\n";
	print $prot->seq."\n";
	
}
