#!/usr/bin/perl

# getReadsFromListCheckPairs.pl
# written by Linnéa Smeds        May 2011, edited Apr 2013
# ========================================================
# Takes a pair of fastq files and extract all reads that 
# are listed in a given file, IF the read exist in both
# files in the pair!
# ========================================================


use strict;
use warnings;

my $in1 = $ARGV[0];
my $in2 = $ARGV[1];
my $readList = $ARGV[2];
my $outpref = $ARGV[3];
my $outsuff = $ARGV[4];

unless($outsuff) {
	$outsuff=""; # Originally there were no $outsuff
}

my $time = time;

my %reads = ();
open(LST, $readList);
while(<LST>) {
	chomp($_);
	$reads{$_}{'type'}=0;
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

my $out1 = $outpref.".".$outsuff."1.fastq";
my $out2 = $outpref.".".$outsuff."2.fastq";

open(OUT1, ">$out1");
open(OUT2, ">$out2");

# Save reads in file 2
while(<IN2>) {

	my $line=$_;
	my @tabs = split(/\s+/, $line);
	my $id = $tabs[0];
	my $seq=<IN2>;
	my $plus=<IN2>;
	my $score=<IN2>;

	$id =~ s/@//;
	$id =~ s/\/\d//;
	chomp($id);

	if(defined $reads{$id}) {
    #    print "looking at line $line\n";
		$reads{$id}{'id2'}=$line;
		$reads{$id}{'seq2'}=$seq;
		$reads{$id}{'score2'}=$score;
	}
}
close(IN2);


# Going through the reads in file 1 and print those that also exist in file 2
while(<IN1>) {
	my @tabs = split(/\s+/, $_);
	my $id = $tabs[0];
	my $seq=<IN1>;
	my $plus=<IN1>;
	my $score=<IN1>;

	$id =~ s/@//;
	$id =~ s/\/\d//;
	chomp($id);
	
	if(defined $reads{$id}{'id2'}) {
		print OUT1  join(" ", @tabs)."\n". $seq . "+\n" . $score;
		print OUT2  $reads{$id}{'id2'} . $reads{$id}{'seq2'} . "+\n" . $reads{$id}{'score2'};
		delete $reads{$id}; #(reads should be unique, so no need saving after it's been used)
	}
}
close(OUT1);
close(OUT2);
close(IN1);
close(IN2);

$time = time - $time;
print "Time elapsed: $time sec.\n";
