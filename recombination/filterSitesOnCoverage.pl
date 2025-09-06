#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# filterSitesOnCoverage.pl
# written by Linnéa Smeds                        3 May 2015
# ---------------------------------------------------------
# DESCRIPTION:
# 
# Takes a file 
#Chr15	4192	4193	0|0:1|1:1|0:0|1:0|0:0|0:GP	35:35:23:37:30:33:34:23:21:34:28
#Chr15	12025	12026	1|1:0|0:0|1:1|0:1|0:1|1:GP	46:38:33:28:42:34:47:40:59:37:35
#Chr15	12110	12111	0|0:1|1:1|0:0|1:0|1:0|0:GP	38:31:32:29:36:28:35:30:39:37:28

# ---------------------------------------------------------
# Example 

use strict;
use warnings;

# Input parameters
my $FILE = $ARGV[0];
my $THRES = $ARGV[1];
my $COLUMNS = $ARGV[2];

# make array of columns
my @col=split(/,/, $COLUMNS);

#open(OUT, ">$OUT");		#Initiating outfile

# GO THROUGH THE FILE
open(IN, $FILE);
while(<IN>) {
	my @t=split(/\s+/,$_);

	my $printflag="on";
	my @cov=split(/:/, $t[4]);

	foreach my $c (@col) {
#		print "DEBUG: Checking $c: cov is".$cov[$c-1]."\n";
		if($cov[$c-1] eq "." || $cov[$c-1]<$THRES){
			
			$printflag="off";
			last;
		}
	}
	
	if($printflag eq "on") {
		print $_;
	}
}
close(IN);

