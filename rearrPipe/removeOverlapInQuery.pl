#!/usr/bin/perl

# # # # # #
# removeOverlapInQuery.pl	
# written by Linnéa Smeds                          Nov 2012
# ---------------------------------------------------------
# DESCRIPTION:
# 

use strict;
use warnings;
use List::Util qw(min max);

# Input parameters
my $ANCHORFILE = $ARGV[0];
my $OUT = $ARGV[1];

open(IN, $ANCHORFILE);
my %hash = ();
my @rows = ();
my $rowcnt = 1;
while(<IN>) {
	unless ($_ eq "") {
		my @tab = split(/\s+/, $_);
		$hash{$tab[4]}{$tab[5]}{'refid'} = $tab[0];
		$hash{$tab[4]}{$tab[5]}{'refstart'} = $tab[1];
		$hash{$tab[4]}{$tab[5]}{'refstop'} = $tab[2];
		$hash{$tab[4]}{$tab[5]}{'refdir'} = $tab[3];
		$hash{$tab[4]}{$tab[5]}{'stop'} = $tab[6];
		$hash{$tab[4]}{$tab[5]}{'dir'} = $tab[7];
		$hash{$tab[4]}{$tab[5]}{'score'} = $tab[8];
		$rows[$rowcnt] = $_;
		$rowcnt++;
		print "adding ".$tab[4]." with value ".$tab[5]."\n";
	}
}
close(IN);


#Go through scaffolds
foreach my $scaf (keys %hash) {
	my $oldstart;
	my $removeFlag = "off";
	my $cnt = 0;
	my $lastline;

	#Go through start positions 
	foreach my $start (sort {$a<=>$b} keys %{$hash{$scaf}}) {
		if($cnt>0) {
			#If this segment is overlapping with previous one
			if($hash{$scaf}{$oldstart}{'stop'}>=$start) {
				
				print "$scaf with start $oldstart is overlapping with $start\n";
				my $oldlen = $hash{$scaf}{$oldstart}{'stop'}-$oldstart+1;
				my $len = $hash{$scaf}{$start}{'stop'}-$start+1;
	 			my $oldscore = $hash{$scaf}{$oldstart}{'score'};
	 			my $score = $hash{$scaf}{$start}{'score'};
			
		
				if($oldlen>$len && $oldscore>1.5*$score) {
					print "old $oldstart is better, save that one and remove start $start!\n";
					delete $hash{$scaf}{$start};
					$start = $oldstart;
				}
				elsif($len>$oldlen && $score>1.5*$oldscore) {
					print "new $start is better, save that one and remove \n";
					delete $hash{$scaf}{$oldstart};
				}
				else {
					print "both are bad, remove!\n";
					#But we can only remove one of them now, to have something to compare with!
					#(keep the one with highest score)
					if($score>$oldscore) {
						delete $hash{$scaf}{$oldstart};
					}
					else {
						delete $hash{$scaf}{$start};
						$start = $oldstart;
					}
					$removeFlag="on";
				}
			}
			else {
				if($removeFlag eq "on") {
					delete $hash{$scaf}{$oldstart};
				}
				$removeFlag="off";
			}
		}
		$oldstart = $start;
		$cnt++;
	}
	if($removeFlag eq "on") {
		delete $hash{$scaf}{$oldstart};
	}
}

	
#Go through the hash again and print in in original order
open(OUT, ">$OUT");
foreach my $line (@rows) {
	my @tabs = split(/\s+/, $line);
	if(defined $hash{$tabs[4]}{$tabs[5]}) {
		print OUT $line;
	}
}
close(OUT);


