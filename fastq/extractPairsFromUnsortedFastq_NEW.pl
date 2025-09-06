#!/usr/bin/perl

# extractPairsFromUnsortedFastq.pl
# written by Linnéa Smeds                         Dec 2011
# NOTE!! THE FIRST SCRIPT EXTRACTED THE SEQUENCE FROM THE 
# ORIGINAL FILES; SO IT DIDN'T WORK FOR EXTRACTING READS
# FROM FILES THAT HAD BEEN TRIMMED AFTER!!!!!
# THIS VERSION TAKES CARE OF THAT AND SAVES THE SEQ AND 
# QUAL FROM THE QUERY FILES.
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
my $outsuff = $ARGV[4];

unless($outsuff) {
	$outsuff=""; # Originally there were no $outsuff
}

my $out1 = $prefix.".".$outsuff."1.fastq";
my $out2 = $prefix.".".$outsuff."2.fastq";
my $out3 = $prefix.".".$outsuff."unpaired.fastq";

my %reads;
open(IN, $trimmed1);
while(<IN>) {
	chomp($_);
	#$_ =~ s/\/\d//;
	my @tab = split(/\s+/, $_);
	#$reads{$_}=1;
	$reads{$tab[0]}{'type'}=1;
#	print "save read 1 ".$tab[0]."\n";
	$reads{$tab[0]}{'seq1'}=<IN>;
	<IN>;
	$reads{$tab[0]}{'qual1'}=<IN>;
}
close(IN);

open(IN, $trimmed2);
while(<IN>) {
	chomp($_);
	#$_ =~ s/\/\d//;
	#$_ =~ s/\/\d//;
	my @tab = split(/\s+/, $_);
	if(defined $reads{$tab[0]}) {
		$reads{$tab[0]}{'type'}=3;
	}
	else {
		$reads{$tab[0]}{'type'}=2;
	}
	$reads{$tab[0]}{'seq2'}=<IN>;
	<IN>;
	$reads{$tab[0]}{'qual2'}=<IN>;

}
close(IN);

open(OUT1, ">$out1");
open(OUT2, ">$out2");
open(OUT3, ">$out3");

open(IN1, $origFile1);
open(IN2, $origFile2);
while(<IN1>) {

#	my $read = $_;
#	chomp($read);
#	$read =~ s/\/\d//;
	my @tab = split(/\s+/, $_);
	my $read = $tab[0];

	my $head1 = $_;	
	my $seq1 = <IN1>;
	my $plus1 = <IN1>;
	my $qual1 = <IN1>;
	my $head2 = <IN2>;
	my $seq2 = <IN2>;
	my $plus2 = <IN2>;
	my $qual2 = <IN2>;
	

	if(exists $reads{$read}) {
		if($reads{$read}{'type'}==1) {
			print OUT3 $head1.$reads{$read}{'seq1'}.$plus1.$reads{$read}{'qual1'};
		}
		elsif($reads{$read}{'type'}==2) {
			print OUT3 $head2.$reads{$read}{'seq2'}.$plus2.$reads{$read}{'qual2'};
		}
		elsif($reads{$read}{'type'}==3) {
			print OUT1 $head1.$reads{$read}{'seq1'}.$plus1.$reads{$read}{'qual1'};
			print OUT2 $head2.$reads{$read}{'seq2'}.$plus2.$reads{$read}{'qual2'};
		}
	}
	delete $reads{$read};
}
close(IN1);
close(IN2);
