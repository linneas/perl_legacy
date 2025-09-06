#!/usr/bin/perl


# # # # # #
# sepChromToFiles.pl
# written by Linnéa Smeds		       Jan 2011
# =====================================================
# Takes a merged file for all chromosomes (chrom name
# in the first column) and prints the data to separate
# files named ChrN + some suffix.
# =====================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;

# Input parameters
my $bigFile = $ARGV[0];	 	   
my $suffix = $ARGV[1];
my $headerFile = $ARGV[2];

my $headflag="off";
if(-e $headerFile) {
	$headflag="on";
}

open(IN, $bigFile);
while(<IN>) {
	my @line = split(/\s+/, $_);
	my $chr = shift(@line);

	my $outfile = $chr.$suffix;

	print "printing to $outfile\n";
	open(OUT, ">$outfile");
	if($headflag == "on") {
		open(H, $headerFile);
		while(<H>) {
			print OUT $_;
		}
		close(H);
	}
	print OUT join("\t", @line)."\n";


	my $next = <IN>;
	@line = split(/\s+/, $next);
	my $thischr = shift(@line);
	while ($thischr eq $chr) {
		print "next row is ".join("\t", @line)."\n";
		print OUT join("\t", @line)."\n";
	#	if(eof(IN)) {
	#		last;
	#	}	
		$next = <IN>;
		@line = split(/\s+/, $next);
		$thischr=shift(@line);
	}
	seek(IN, -length($next), 1);

	close(OUT);
}
close(IN);
