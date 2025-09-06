#!/usr/bin/perl


# # # # # #
# breakpointToTelomereDist_on_concat.pl
# written by Linnéa Smeds                    Dec 2012
# modified in Jan 2013 to divide absolute distances
# into groups with respect to chromosome size.
# ===================================================
# Takes a list of breakpoints (chrom, start and stop)
# and a file with chromosome lengths, and calculate
# the shortest distance to telomeres and prints the
# relative distance to one file and the absolute dist
# to another file depending on chrom size.
# ===================================================
# Usage: 

use strict;
use warnings;
use List::Util qw(max min);


# Input parameters
my $BREAKPOINTS = $ARGV[0];	#scaffold, start, stop
my $KARYOTYPE = $ARGV[1];	#length or Karyotype (change other settings)
my $OUTPREFIX = $ARGV[2];

# Other parameters
my $chromColumn= 0;
my $lengthColumn = 1;	#changed from 5 in karyotype file


# Output files
my $RELOUT = $OUTPREFIX."_relDistToTelo.txt";
my $BIGOUT = $OUTPREFIX."_absDistToTeloBIG.txt";
my $MEDOUT = $OUTPREFIX."_absDistToTeloMEDIUM.txt";
my $SMALLOUT = $OUTPREFIX."_absDistToTeloSMALL.txt";
open(REL, ">$RELOUT");
open(BIG, ">$BIGOUT");
open(MED, ">$MEDOUT");
open(SML, ">$SMALLOUT");


#Find chromlength from karyotype
my %lengths = ();
open(IN, $KARYOTYPE);
while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	$lengths{$tab[$chromColumn]}=$tab[$lengthColumn];
}
close(IN);



# Go through the breakpoints and save start and stop on scaffold pos
open(IN, $BREAKPOINTS);
my %blocks = ();
my $printflag = "off";
my $cnt = 1;
my $prevend = "";
while(<IN>) {
	my @tab = split(/\s+/, $_);

	print "looking at ".$tab[0]." with length ".$lengths{$tab[0]}."\n";

	my $dist = min($tab[1], $lengths{$tab[0]}-($tab[2]-1));
	my $rel = $dist/$lengths{$tab[0]};
	print REL $tab[0]."\t".$rel."\n";
	if($lengths{$tab[0]}>=25000000) {
		print BIG $tab[0]."\t".$dist."\n";
	}
	elsif($lengths{$tab[0]}<25000000 && $lengths{$tab[0]}>=10000000) {
		print MED $tab[0]."\t".$dist."\n";
	}
	else {
		print SML $tab[0]."\t".$dist."\n";
	}
}
close(REL);
close(BIG);
close(MED);
close(SML);
close(IN);
	



