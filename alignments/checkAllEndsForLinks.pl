#!/usr/bin/perl

# checkAllEndsForLinks.pl
# written by Linnéa Smeds                       15 May 2012
# =========================================================
#
# =========================================================


use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $bam = $ARGV[0];
my $scaffolds = $ARGV[1];
my $LengthFile = $ARGV[2];
my $limit = $ARGV[3];
my $output = $ARGV[4];

my $thres = 1.5;

# Save all lengths in a hash
my %lengths = ();
open(IN, $LengthFile);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	$lengths{$tab[0]}=$tab[1];
}
close(IN);

#Open outfile
#open(OUT, ">$output");

# Go through the links for each scaffold
open(ALL, $scaffolds);
while(<ALL>) {
	my @tab = split(/\s+/,$_);
	my $scaff = $tab[0];

	print "DEBUG: Looking at $scaff\n";
 
	my $temp = "tempfile";

	# Check start of scaffold
	system("samtools view $bam $scaff |awk '(\$4<$limit && \$5!=0 && \$7!=\"=\"){print}' |cut -f7 |sort |uniq -c |sort -nr >$temp");
	
	open(TMP, $temp);

	my ($s1, $firstNo, $firstName) = split(/\s+/, <TMP>);
	my ($s2, $secNo, $secName) = split(/\s+/, <TMP>);
	my ($s3, $thirdNo, $thirdName) = split(/\s+/, <TMP>);
	close(TMP);	

	print "first is $firstName, second is $secName and third is $thirdName\n";

	if($firstNo/($secNo+$thirdNo)>$thres) {
		print "Start of $scaff is significantly connected to $firstName\n";
	}

	# Check if the links are in the start/end of the new scaffold
	my $toStart = `samtools view $bam $scaff |awk '(\$4<$limit && \$5!=0 && \$7==\"$firstName\" && \$8<$limit){print}' |wc -l`;
	chomp($toStart);
	my $tempEnd = $lengths{$firstName}-$limit;
	my $toEnd = `samtools view $bam $scaff |awk '(\$4<$limit && \$5!=0 && \$7==\"$firstName\" && \$8>$tempEnd){print}' |wc -l`;
	chomp($toEnd);
	print "Start of $scaff have $toStart links to start of $firstName and $toEnd links to end\n";

		

	 # Check end of scaffold
	$tempEnd = $lengths{$scaff}-$limit;
	system("samtools view $bam $scaff |awk '(\$4>$tempEnd && \$5!=0 && \$7!=\"=\"){print}' |cut -f7 |sort |uniq -c |sort -nr >$temp");
	
	open(TMP, $temp);

	($s1, $firstNo, $firstName) = split(/\s+/, <TMP>);
	($s2, $secNo, $secName) = split(/\s+/, <TMP>);
	($s3, $thirdNo, $thirdName) = split(/\s+/, <TMP>);
	close(TMP);

	print "first is $firstName, second is $secName and third is $thirdName\n";

	if($firstNo/($secNo+$thirdNo)>$thres) {
		print "End of $scaff is significantly connected to $firstName\n";
	}

	# Check if the links are in the start/end of the new scaffold
	$toStart = `samtools view $bam $scaff |awk '(\$4<$limit && \$5!=0 && \$7==\"$firstName\" && \$8<$limit){print}' |wc -l`;
	chomp($toStart);
	$tempEnd = $lengths{$firstName}-$limit;
	$toEnd = `samtools view $bam $scaff |awk '(\$4<$limit && \$5!=0 && \$7==\"$firstName\" && \$8>$tempEnd){print}' |wc -l`;
	chomp($toEnd);

	print "End of $scaff have $toStart links to start of $firstName and $toEnd links to end\n";

		


}
close(ALL);
