#!/usr/bin/perl

# # # # # #
# meanCoveragePerScaffold.pl
# written by Linnéa Smeds                    4 Mar 2014
# =====================================================
# Takes file with all the scaffold names and lengths
# and a pileup file, and calculates the mean coverage
# per scaffold (both using covered and uncovered bases).
# =====================================================
# Usage: perl meanCoveragePerScaffold.pl lengthfile pileup out


use strict;
use warnings;
use List::Util qw[min max];
#use Statistics::Basic qw(:all nofill);

# Input parameters
my $SCAFLEN = $ARGV[0];
my $PILEUP = $ARGV[1];
my $OUTPREF = $ARGV[2];

# Open outfiles
my $out1=$OUTPREF.".scafstats";
my $out2=$OUTPREF.".mstats";
open(OUT1, ">$out1");
open(OUT2, ">$out2");

# Save lengths
my %lengths = ();
open(LEN, $SCAFLEN);
my $genomelen=0;
while(<LEN>) {
	my ($scaf, $len)=split(/\s+/, $_);
	$lengths{$scaf}=$len;
	$genomelen+=$len;
}
close(LEN);

# Go through the pileup
open(PILE, $PILEUP);
my ($totcov, $totbp) = (0, 0);
while(<PILE>) {
	my @arr = split(/\s+/, $_);

	my $cov=$arr[3];
	my $cnt=1;

	my $next = <PILE>;
	my @nextarr =split(/\s+/, $next);
	while ($nextarr[0] eq $arr[0]) {
		chomp($next);
		$cov+=$nextarr[3];
		$cnt++;
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
	my $covbpcov=$cov/$cnt;
	my $allbpcov=$cov/$lengths{$arr[0]};
	my $covbp=$cnt/$lengths{$arr[0]};
	$covbpcov = sprintf "%.2f", $covbpcov;
	$allbpcov = sprintf "%.2f", $allbpcov;
	$covbp = sprintf "%.2f", $covbp;
	print OUT1 $arr[0]."\t".$cnt."\t".$cov."\t".$covbpcov."\t".$covbp."\t".$allbpcov."\n";

}
close(PILE);

# Stats for tot genome
my $covbpcov=$totcov/$totbp;
my $allbpcov=$totcov/$genomelen;
my $covbp=$totbp/$genomelen;
$covbpcov = sprintf "%.2f", $covbpcov;
$allbpcov = sprintf "%.2f", $allbpcov;
$covbp = sprintf "%.2f", $covbp;
print OUT2 $totbp."\t".$totcov."\t".$covbpcov."\t".$covbp."\t".$allbpcov."\n";

