#!/usr/bin/perl

# # # # # #
# sortScaffolds.pl           
# written by Linnéa Smeds       May 30 2011, mod Sept 2012
# ========================================================
# 
# ========================================================
# usage perl 

use strict;
use warnings;

my $in = $ARGV[0];
my $sortFlag = $ARGV[1];
my $prefix = $ARGV[2];
my $outpref = $ARGV[3];



unless(defined $sortFlag) {
	$sortFlag = "UP";
}

my $outFa = $outpref.".reformated.fa";
my $outMap = $outpref.".reformated.map";

my %seqHash = ();

open(IN, $in);
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
		seek(IN, -length($next), 1);

		$seqHash{$head}{'seq'} = $seq;
		$seqHash{$head}{'len'} = length($seq);
	}
}
close(IN);

my $cnt = 1;

open(OUT, ">$outFa");
open(MAP, ">$outMap");

if($sortFlag eq "UP") {
	foreach my $key (sort {$seqHash{$a}{'len'} <=> $seqHash{$b}{'len'}} keys %seqHash) {
		my $outname = $cnt;
		while(length($outname)<4) {
			$outname = "0".$outname;
		}
		$outname = $prefix.$outname;
		print OUT ">$outname\n";
		print MAP "$key\t$outname\n";
		my @blocks = split(/(.{100})/i, $seqHash{$key}{'seq'});
		foreach my $bl (@blocks) {
			if($bl ne "") {
				print OUT "$bl\n";
			}
		}
		$cnt++;	
	}
}
else {
	foreach my $key (sort {$seqHash{$b}{'len'} <=> $seqHash{$a}{'len'}} keys %seqHash) {
		my $outname = $cnt;
		while(length($outname)<4) {
			$outname = "0".$outname;
		}
		$outname = $prefix.$outname;
		print OUT ">$outname\n";
		print MAP "$key\t$outname\n";
		my @blocks = split(/(.{100})/i, $seqHash{$key}{'seq'});
		foreach my $bl (@blocks) {
			if($bl ne "") {
				print OUT "$bl\n";
			}
		}
		$cnt++;	
	}
}

