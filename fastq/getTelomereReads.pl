#!/usr/bin/perl

#Written by Nagarjun

use strict;
use warnings;

my $in1 = $ARGV[0];
my $in2 = $ARGV[1];
my $outpref = $ARGV[2];

open(IN1, $in1);
open(IN2, $in2);

my $out1 = $outpref."_telo1.fastq";
my $out2 = $outpref."_telo2.fastq";

open(OUT1, ">$out1");
open(OUT2, ">$out2");

my $totCnt=0;
my $saveCnt=0;
while(<IN1>) {
my @readhead=split(' ',$_);
	my $id = $readhead[0];
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

#	if(($seq=~m/TTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGG/)||($seq=~m/CCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAA/)||($seq2=~m/TTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGG/)||($seq2=~m/CCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAA/)){
	if(($seq=~m/TTAGGGTTAGGGTTAGGGTTAGGG/)||($seq=~m/CCCTAACCCTAACCCTAACCCTAA/)||($seq2=~m/TTAGGGTTAGGGTTAGGGTTAGGG/)||($seq2=~m/CCCTAACCCTAACCCTAACCCTAA/)){

		print OUT1  $_ . $seq . $plus . $score;
		print OUT2  $id2 . $seq2 . $plus2 . $score2;
	}
}
close(OUT1);
close(OUT2);
close(IN1);
close(IN2);

