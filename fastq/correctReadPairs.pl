#!/usr/bin/perl

# correctReadPairs.pl
# written by Linnéa Smeds                     24 Sept 2013
# =========================================================
# Needs to be run after files created (before 20130924) by 
# "getreadsFromListCheckPairs.pl", since it had a bug that
# caused it to print all pairs on the list even if the
# second read in the pair was missing (making pair1 file
# bigger than pair2).
# =========================================================


use strict;
use warnings;

my $in1 = $ARGV[0];
my $in2 = $ARGV[1];
my $outpref = $ARGV[2];
my $outsuff = $ARGV[3];

unless($outsuff) {
	$outsuff=""; # Originally there were no $outsuff
}

my $time = time;

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


my $out1 = $outpref.".".$outsuff."1.fastq";
my $out2 = $outpref.".".$outsuff."2.fastq";

open(OUT1, ">$out1");
open(OUT2, ">$out2");

my %reads = ();
# Save reads in file 2
while(<IN2>) {

	my $line=$_;
	my @tabs = split(/\s+/, $line);
	my $id = $tabs[0];

	if($id =~ m/^@/) {
		my $seq=<IN2>;
		my $plus=<IN2>;
		my $score=<IN2>;

		$id =~ s/@//;
		$id =~ s/\/\d//;
		chomp($id);

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
		delete $reads{$id};
	}
}
close(OUT1);
close(OUT2);
close(IN1);
close(IN2);

$time = time - $time;
print "Time elapsed: $time sec.\n";
