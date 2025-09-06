#!/usr/bin/perl

# # # # #
# statistics.pl          
# written by Linnéa Smeds                         Nov 2013
# ========================================================
# A combination of the scripts getSeqLengthStats.pl and
# NDistrFromFasta.pl, plus it also reports the number of
# sequences.
# ========================================================
# usage perl 

use strict;
use warnings;

my $in = $ARGV[0];
my $time = time;

open(IN, $in);

my $totLen=0;
my @summary;
my $cnt=0;
my $seq = "";
my $Nsum=0;
while(<IN>) {
	
	if($_ =~ m/^>/) {
		$totLen+=length($seq);
		if ($cnt!=0) {
			push(@summary, length($seq)); 
			my @hits = $seq =~ m/(N+)/gi;
			foreach my $h (@hits) {
				$Nsum+=length($h);
			}
		}
		$seq="";
		$cnt++;
	}
	else {
		chomp($_);
		$seq.=$_;
	}
}

$totLen+=length($seq);
push(@summary, length($seq)); 
my @hits = $seq =~ m/(N+)/gi;
	foreach my $h (@hits) {
	$Nsum+=length($h);
}
$seq="";

my $mean = int($totLen/$cnt+0.5);
my $SeqNo=scalar(@summary);

print "No of Seq: $SeqNo\n";
print "Total length: $totLen\n";
print "Avg length: $mean\n";

@summary=sort{$b<=>$a} @summary; 
my ($count,$half)=(0,0);
for (my $j=0;$j<@summary;$j++){
	$count+=$summary[$j];	
	if (($count>=$totLen/2)&&($half==0)){
		print "N50: $summary[$j]\n";
		$half=$summary[$j]
	}elsif ($count>=$totLen*0.9){
		print "N90: $summary[$j]\n";
		last;
	}

}
print "No of Ns: $Nsum\n";

$time = time - $time;
print "Time elapsed: $time sec.\n";
