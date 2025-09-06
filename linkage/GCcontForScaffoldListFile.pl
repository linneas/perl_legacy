#!/usr/bin/perl

# # # # # #
# GCcontForScaffoldListFile.pl
# written by Linnéa Smeds                      28 Sept 2011
# =========================================================
# Takes a scaffold list file with 4 columns (scaffold name,
# length, order, and some info), and a window-list file
# with a certain window size, and prints the GC content 
# to a new file ordered after the list file (ie ordered as
# the FC genome).
# =========================================================


use strict;
use warnings;

#Input parameters
my $scafList = $ARGV[0];	#Four columns (scaff, length, sign, comment)
my $windList = $ARGV[1];	#Five columns (scaff, start, stop, cov, GC, Ns)
my $out = $ARGV[2];

#Save all scaffolds
my %scaffolds = ();
open(IN, $scafList);
my $cnt = 1;
while(<IN>) {
	my @tabs = split(/\s+/, $_);
	$scaffolds{$tabs[0]}{'order'} = $cnt;
	$scaffolds{$tabs[0]}{'sign'} = $tabs[2];
	$scaffolds{$tabs[0]}{'array'} = [];
	$cnt++;
}
close(IN);

#Go through the window list
open(IN, $windList);
while(<IN>) {
	unless(/MEANCOV/) {
		my ($scaff, $start, $end, $cov, $GC, $Ns, $CDS, $CDSfrac) = split(/\s+/, $_);
		if(defined $scaffolds{$scaff}) {
			push(@{$scaffolds{$scaff}{'array'}}, "$scaff\t$start\t$end\t$cov\t$GC\t$CDSfrac\n");
		}
	}
}
close(IN);


open(OUT, ">$out");
foreach my $key (sort {$scaffolds{$a}{'order'}<=>$scaffolds{$b}{'order'}} keys %scaffolds){
	if($scaffolds{$key}{'sign'} eq "-") {
		@{$scaffolds{$key}{'array'}}=reverse(@{$scaffolds{$key}{'array'}});
	}
	foreach(@{$scaffolds{$key}{'array'}}) {
		print OUT $_;
	}
}














