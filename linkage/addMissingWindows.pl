#!/usr/bin/perl


# # # # # #
# addMissingWindows.pl
# written by Linnéa Smeds		               Feb 2012
# =====================================================
# Takes a table with all desired windows, listed with
# scaffold, window start and end, and a possibly
# uncomplete table, together with the number of "extra" 
# columns in that file. Then prints the table again, 
# adding any missing windows with one "NA" for each 
# column.
# =====================================================
# Usage: perl addMissingWindows.pl <TABLE> <WINDOW FILE>
#							<NO OF COLUMNS> <OUTPUT> 
#

use strict;
use warnings;

# Input parameters
my $table = $ARGV[0];	 
my $specWindFile = $ARGV[1];
my $noCol = $ARGV[2];
my $outfile = $ARGV[3];	

# reference file, columns for scaffold and start
my $scafCol = 0;
my $windCol = 1; 

# your file, columns for scaffold and start
my $yourScaf = 0;
my $yourStart = 1;

my ($rmCnt, $totCnt)=(0,0);
open(TAB, $table);
my $header = "";
my %rows = ();
while(<TAB>) {
	if(/#/) {
		$header.=$_;
	}
	else {
		my @tab = split(/\s+/, $_);
		$rows{$tab[$yourScaf]}{$tab[$yourStart]} = $_;
	}	
}
close(TAB);


open(OUT, ">$outfile");
print OUT $header;
open(IN, $specWindFile);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	if(defined $rows{$tab[$scafCol]}{$tab[$windCol]}) {
		print OUT $rows{$tab[$scafCol]}{$tab[$windCol]};
	}
	else {
		print OUT $tab[$scafCol]."\t".$tab[$windCol]."\t".$tab[$windCol+1]."\tNA"x $noCol ."\n";
	}
}
close(IN);
close(OUT);

