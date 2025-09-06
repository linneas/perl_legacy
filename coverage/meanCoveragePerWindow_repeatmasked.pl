#!/usr/bin/perl

# # # # # #
# meanCoveragePerWindow_repeatMasked.pl
# written by Linnéa Smeds                   24 Mar 2014
# modified from meanCoveragePerScaffold_repeatmasked.pl 
# to look att windows instead.
# =====================================================
# Takes file with all the scaffold names and lengths
# and a pileup file, and calculates the mean coverage
# per scaffold (both using covered and uncovered bases).
# MODIFIED: This version also takes a repeatBed file
# and ONLY checks coverage for non repeat regions!!
# =====================================================
# Usage: perl meanCoveragePerScaffold.pl lengthfile pileup out


use strict;
use warnings;
use List::Util qw[min max];
#use Statistics::Basic qw(:all nofill);

# Input parameters
my $SCAFLEN = $ARGV[0];
my $PILEUP = $ARGV[1];
my $REPEATS = $ARGV[2];	#PROPER BED FILE!!
my $WINDSIZE = $ARGV[3];
my $OUTPREF = $ARGV[4];

# Open outfiles
my $out1=$OUTPREF.".rm.windstats";
open(OUT1, ">$out1");

# Save lengths
my %lengths = ();
open(LEN, $SCAFLEN);
my $genomelen=0;
my $repMasklen=0;
while(<LEN>) {
	my ($scaf, $len)=split(/\s+/, $_);
	$lengths{$scaf}{'full'}=$len;
	$lengths{$scaf}{'rm'}=$len;
#	if($scaf eq "scaffold4"){
#		print "adding $len bases to $scaf len\n";
#	}
	$genomelen+=$len;
	$repMasklen+=$len;
}
close(LEN);

# Go through repeats
my %repeats = ();
open(REP, $REPEATS);
while(<REP>) {
	my ($scaf, $start, $stop)=split(/\s+/, $_);
	if(defined $lengths{$scaf}) {
		for(my $i=$start+1; $i<=$stop; $i++) {
			$repeats{$scaf}{$i}=1;
		}
 		my $rmlen=$stop-$start;
		$lengths{$scaf}{'rm'}-=($stop-$start);
#		if($scaf eq "scaffold4"){print "removing $rmlen bases from $scaf len\n";}
		$repMasklen-=($stop-$start);
	}
}
close(REP);
#print "after repeat loop, there are ".$lengths{"scaffold4"}{'rm'}." bases left for scaffold4\n";
#print "after repeat loop, there are $repMasklen bases left in repMasklen\n";

# Go through the pileup
open(PILE, $PILEUP);
my ($totcov, $totbp) = (0, 0);
while(<PILE>) {
	my @arr = split(/\s+/, $_);

 	my ($cov, $cnt)=(0,0);
#	print "looking at ".$arr[0].", pos ".$arr[1]."\n";
#	if(defined $repeats{$arr[0]}{$arr[1]}) {
#		print "\tthis base is in a repeat!\n";
#	}
	unless(defined $repeats{$arr[0]}{$arr[1]}) {
		$cov=$arr[3];
		$cnt=1;
	}
	delete $repeats{$arr[0]}{$arr[1]};

	my $next = <PILE>;
	my @nextarr =split(/\s+/, $next);
	while ($nextarr[0] eq $arr[0]) {
		chomp($next);
		unless(defined $repeats{$nextarr[0]}{$nextarr[1]}) {
			$cov+=$nextarr[3];
			$cnt++;
		}
		delete $repeats{$nextarr[0]}{$nextarr[1]};
		if(eof(PILE)) {
			last;
		}	
		$next = <PILE>;
		@nextarr =split(/\s+/, $next);
	}
#	unless(eof(LST)) {
#		print "inside unless\n";
#		print "putting back $next"; 
		seek(PILE, -length($next), 1);	
#	}

	$totcov+=$cov;
	$totbp+=$cnt;
	my $covbpcov = "NA";
	unless($cnt==0) {
		$covbpcov=$cov/$cnt;
		$covbpcov = sprintf "%.2f", $covbpcov;
	}
	my $allbpcov="NA";
	my $covbp="NA";
	unless($lengths{$arr[0]}{'rm'}==0) {
#		print "the total coverage is $cov and the repeat masked length is ".$lengths{$arr[0]}{'rm'}."\n";
#		print "the number of covered bases is $cnt\n";
		$allbpcov=$cov/$lengths{$arr[0]}{'rm'};
		$covbp=$cnt/$lengths{$arr[0]}{'rm'};	
		$allbpcov = sprintf "%.2f", $allbpcov;
		$covbp = sprintf "%.2f", $covbp;
	}
	
	
	print OUT1 $arr[0]."\t".$cnt."\t".$cov."\t".$covbpcov."\t".$covbp."\t".$allbpcov."\n";

}
close(PILE);

# Stats for tot genome
if($repMasklen<0) {print "WARNING: repmasklen is $repMasklen\n";}

my $covbpcov="NA";
unless($totbp==0) {
	$covbpcov=$totcov/$totbp;
	$covbpcov = sprintf "%.2f", $covbpcov;
}
my $allbpcov="NA";
my $covbp = "NA";
unless($repMasklen==0) {
	$allbpcov=$totcov/$repMasklen;
	$covbp=$totbp/$repMasklen;
	$allbpcov = sprintf "%.2f", $allbpcov;
	$covbp = sprintf "%.2f", $covbp;
}
print OUT2 $totbp."\t".$totcov."\t".$covbpcov."\t".$covbp."\t".$allbpcov."\n";

