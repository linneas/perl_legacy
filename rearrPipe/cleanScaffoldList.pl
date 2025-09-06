#!/usr/bin/perl

# # # # # #
# cleanScaffoldList.pl	
# written by Linnéa Smeds                         June 2017
# ---------------------------------------------------------
# DESCRIPTION: Takes a modified anchor file with scaffold
# name, orientation and length, where adjacent lines from
# the same scaffold (and with the same orientation) have 
# been merged together. Returns a list with each scaffold
# only appearing once (only the longest occurence is saved)
# ---------------------------------------------------------
# USAGE: awk '{len=$7-$6+1; print $5"\t"$8"\t"len}'  file.anchors.cleaned | \
#		awk '{if(NR==1){psc=$1; pdir=$2; sum=$3}else{if($1==psc && $2==pdir) \
#		{sum+=$3}else{print psc"\t"pdir"\t"sum; psc=$1; pdir=$2; sum=$3}}} \
#		END{print psc"\t"pdir"\t"sum}' | perl cleanScaffoldList.pl - >out.list


use strict;
use warnings;
use List::Util qw(min max);

# Input parameters
my $ANCHOR = $ARGV[0];

open(IN, $ANCHOR);
my %hash = ();
my $rowcnt = 1;
while(<IN>) {
	unless ($_ eq "") {
		my ($sc, $ori, $len) = split(/\s+/, $_);

		if(defined $hash{$sc}) {		#This scaffold is already saved
			if($len>$hash{$sc}{'len'}) {	#If this block is bigger, overwrite
				$hash{$sc}{'len'}=$len;
				$hash{$sc}{'no'}=$rowcnt;
				$hash{$sc}{'ori'}=$ori;
			}
		}
		else {					#If the scaffold hasn't been saved yet, save it!
			$hash{$sc}{'len'}=$len;
			$hash{$sc}{'no'}=$rowcnt;
			$hash{$sc}{'ori'}=$ori;
		}
		$rowcnt++;
	}
}
close(IN);


#Go through scaffolds and print them in the correct order
foreach my $scaf (sort {$hash{$a}{'no'}<=>$hash{$b}{'no'}} keys %hash) {
	print $scaf."\t".$hash{$scaf}{'ori'}."\n";
}


