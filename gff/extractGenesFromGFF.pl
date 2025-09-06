#!/usr/bin/perl

# extractGenesFromGFF.pl
# written by Linnéa Smeds                        3 Nov 2011
# =========================================================
# Takes a GFF file and a list of genes, and prints all gff
# entries that involve the genes in question.
# Pipe to grep if only certain types (eg exons) are wanted.
# =========================================================
#
#

use strict;
use warnings;

# Input parameters
my $GFF = $ARGV[0];
my $GeneList = $ARGV[1];

my %genes = ();
open(IN, $GeneList);
while(<IN>) {
	chomp($_);
	$genes{$_}=1;
}
close(IN);

open(IN, $GFF);
my $printflag = "off";
while(<IN>) {
	unless(/^#/) {
		my @tab = split(/\s+/, $_);
		if($tab[2] eq "gene") {
			if(defined $genes{$tab[12]}) {
				$printflag = "on";
				print $_;
			}
			else {
				$printflag = "off";
			}
		}
		else {
			if($printflag eq "on"){
				print $_;
			}
		}
	}
}
close(IN);
