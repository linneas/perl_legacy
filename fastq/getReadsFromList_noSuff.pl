#!/usr/bin/perl

# getReadsFromList.pl
# written by Linnéa Smeds        May 2011, edited Apr 2013
# ========================================================
# Takes a pair of fastq files and extract all reads that 
# are listed in a given file.
# ========================================================


use strict;
use warnings;

my $in1 = $ARGV[0];
my $in2 = $ARGV[1];
my $readList = $ARGV[2];
my $outpref = $ARGV[3];

my $time = time;

my %reads = ();
open(LST, $readList);
while(<LST>) {
	chomp($_);
	$reads{$_}=1;
}
close(LST);

if($in1 =~ m/\.gz$/) {
	open(IN1, "zcat $in1 |");
}
else {
	open(IN1, $in1);
}
if($in2 =~m/\.gz$/) {
	open(IN2, "zcat $in2 |");
}
else {
	open(IN2, $in2);
}

my $hashCnt = scalar(keys %reads);
print "There are $hashCnt different pairs on the list\n";

my $out1 = $outpref."1.fastq";
my $out2 = $outpref."2.fastq";

open(OUT1, ">$out1");
open(OUT2, ">$out2");

my $totCnt=0;
my $saveCnt=0;
while(<IN1>) {

	my @tabs = split(/\s+/, $_);
	my $id = $tabs[0];
	my $seq=<IN1>;
	my $plus=<IN1>;
	my $score=<IN1>;
	my $id2=<IN2>;
	my $seq2=<IN2>;
	my $plus2=<IN2>;
	my $score2=<IN2>;

	$id =~ s/@//;
	$id =~ s/\/\d//;
	chomp($id);

	#print "the read looks like this $id\n";

	if(defined $reads{$id}) {
		print OUT1  join(" ", @tabs)."\n". $seq . $plus . $score;
		print OUT2  $id2 . $seq2 . $plus2 . $score2;
		$saveCnt++;
	}
	$totCnt++;
}
close(OUT1);
close(OUT2);
close(IN1);
close(IN2);

print "In total $saveCnt pairs out of $totCnt were saved\n";
$time = time - $time;
print "Time elapsed: $time sec.\n";
