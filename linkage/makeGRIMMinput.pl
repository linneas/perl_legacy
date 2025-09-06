#!/usr/bin/perl


# # # # # #
# makeGRIMMinput.pl
# written by Linnéa Smeds                    Oct 2012
# ===================================================
# 
# ===================================================
# Usage: 

use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $LINKS = $ARGV[0];
my $KARYOTYPE = $ARGV[1];
my $CHRNAME = $ARGV[2];			
my $OUTPUT = $ARGV[3];


#Open Output
open(OUT, ">$OUTPUT");
print OUT "# " . localtime() ."\n";
print OUT "#\n";
print OUT "# genome1: zebra finch\n";
print OUT "# genome2: collared flycatcher\n";
print OUT "#\n";

#Save karyotype
my %hashmap = ();
open(IN, $KARYOTYPE);
my $start = 0;
while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	$hashmap{$tab[2]}=$start;
	$start+=$tab[5];
}
close(IN);


# Go through links and print in GRIMM format
open(IN, $LINKS);
my $printflag = "off";
my $cnt = 1;
while(<IN>) {
	my @tab = split(/\s+/, $_);
	my $next = <IN>;
	my @nexttab = split(/\s+/, $next);
	my $len1 = max($tab[2],$tab[3])-min($tab[2],$tab[3])+1;
	my $len2 = $nexttab[3]-$nexttab[2],+1;
	
	if($tab[2]<=$tab[3]) {
		my $startpos = $tab[2]+$hashmap{$tab[1]};
		print OUT "0 ".$nexttab[1]." ".$nexttab[2]." ".$len2." 1 ".$CHRNAME." ".$startpos." ".$len1." 1 \n";
	}
	else {
		my $startpos = $tab[3]+$hashmap{$tab[1]};
		print OUT "0 ".$nexttab[1]." ".$nexttab[2]." ".$len2." 1 ".$CHRNAME." ".$startpos." ".$len1." -1 \n";
	}
}
close(IN);
close(OUT);
	
