#!/usr/bin/perl


# # # # # #
# makeGRIMMinput.pl
# written by Linnéa Smeds                    Oct 2012
# BUGFIXED 5 Feb 2013 (fa length was taken from zf)
# ===================================================
# 
# ===================================================
# Usage: 

use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $MAUVE = $ARGV[0];	#Assumes the order chicken, zebra finch, flycatcher
my $CHRNO = $ARGV[1];			
my $OUTPUT = $ARGV[2];

my ($chr1, $chr2, $chr3) = ("gg", "tg", "fa");

if($CHRNO eq "1A") {
	$chr1.="1";
	$chr2.=$CHRNO;
	$chr3.=$CHRNO;
}	
elsif($CHRNO eq "1B") {
	$chr1.="1";
	$chr2.=$CHRNO;
	$chr3.="1";
}
elsif($CHRNO eq "4A") {
	$chr1.="4";
	$chr2.=$CHRNO;
	$chr3.=$CHRNO;
}
else {
	$chr1.=$CHRNO;
	$chr2.=$CHRNO;
	$chr3.=$CHRNO;
}

	

#Open Output
open(OUT, ">$OUTPUT");
print OUT "# " . localtime() ."\n";
print OUT "#\n";
print OUT "# genome1: collared flycatcher\n";
print OUT "# genome2: zebra finch\n";
print OUT "# genome3: chicken\n";
print OUT "#\n";

# Go through MAUVE anchors and print in GRIMM format
open(IN, $MAUVE);
my $printflag = "off";
my $cnt = 1;
<IN>; 	#The header
while(<IN>) {
	my @tab = split(/\s+/, $_);
	unless($tab[0] eq "0" || $tab[2] eq "0" || $tab[4] eq "0") {
		my ($dir1, $dir2, $dir3) = ("+", "+", "+");
		if($tab[0] =~ m/-/) {
			$dir1 = "-";
			$tab[0] =~ s/-//;
			$tab[1] =~ s/-//;
		}
		if($tab[2] =~ m/-/) {
			$dir2 = "-";
			$tab[2] =~ s/-//;
			$tab[3] =~ s/-//;
		}
		if($tab[4] =~ m/-/) {
			$dir3 = "-";
			$tab[4] =~ s/-//;
			$tab[5] =~ s/-//;
		}

		my $len1 = $tab[1]-($tab[0]-1);
		my $len2 = $tab[3]-($tab[2]-1);
		my $len3 = $tab[5]-($tab[4]-1);	#CHANGED 5/2-13! BEFORE $len2 AND $len3 WERE IDENTICAL

		print OUT "0 ".$chr3." ".$tab[4]." ".$len3." ".$dir3." "
						.$chr2." ".$tab[2]." ".$len2." ".$dir2." "
						.$chr1." ".$tab[0]." ".$len1." ".$dir1."\n";
	
	}
}
close(IN);
close(OUT);
	
