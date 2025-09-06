#!/usr/bin/perl

# extractPairsFromUnsortedFastq.pl
# written by Linnéa Smeds                         Dec 2011
# ========================================================
# Takes two paired fastq files that has been filtered 
# separately and sort out which reads that are still
# paired and which should be printed to a singleton file.
# ========================================================
# usage  


use strict;
use warnings;


my $trimmed1 = $ARGV[0];
my $trimmed2 = $ARGV[1];
my $origFile1 = $ARGV[2];
my $origFile2 = $ARGV[3];
my $prefix = $ARGV[4];

my $out1 = $prefix. "_1.fastq";
my $out2 = $prefix. "_2.fastq";
my $out3 = $prefix. "_unpaired.fastq";

my %reads;
open(IN, $trimmed1);
while(<IN>) {
	chomp($_);
	$_ =~ s/\/\d//;
	$reads{$_}=1;
	<IN>;<IN>;<IN>;
}
close(IN);

open(IN, $trimmed2);
while(<IN>) {
	chomp($_);
	$_ =~ s/\/\d//;
	if(defined $reads{$_}) {
		$reads{$_}=3;
	}
	else {
		$reads{$_}=2;
	}
	<IN>;<IN>;<IN>;
}
close(IN);

open(OUT1, ">$out1");
open(OUT2, ">$out2");
open(OUT3, ">$out3");

open(IN1, $origFile1);
open(IN2, $origFile2);
while(<IN1>) {

	my $read = $_;
	chomp($read);
	$read =~ s/\/\d//;

	my $head1 = $_;	
	my $seq1 = <IN1>;
	my $plus1 = <IN1>;
	my $qual1 = <IN1>;
	my $head2 = <IN2>;
	my $seq2 = <IN2>;
	my $plus2 = <IN2>;
	my $qual2 = <IN2>;
	

	if(exists $reads{$read}) {
		if($reads{$read}==1) {
			print OUT3 $head1.$seq1.$plus1.$qual1;
		}
		elsif($reads{$read}==2) {
			print OUT3 $head2.$seq2.$plus2.$qual2;
		}
		elsif($reads{$read}==3) {
			print OUT1 $head1.$seq1.$plus1.$qual1;
			print OUT2 $head2.$seq2.$plus2.$qual2;
		}
	}
	delete $reads{$read};
}
close(IN1);
close(IN2);
