#!/usr/bin/perl

# separate_454fastq_toPairs.pl.pl
# written by Linnéa Smeds                         May 2011
# ========================================================
# Takes a single fasta file in sff_extract format, with 
# the pairs as .f and .r. 
# ========================================================
# usage perl 

use strict;
use warnings;

#Input parameters
my $in = $ARGV[0];
my $outpref = $ARGV[1];

my $time = time;

#Output files
my $out1 = $outpref."_pair1.fastq";
my $out2 = $outpref."_pair2.fastq";
my $out_unp = $outpref."_unpaired.fastq";

open(OUT1, ">$out1");
open(OUT2, ">$out2");
open(OUT3, ">$out_unp");

open(IN, $in);
my ($id,$seq,$plus,$score,$fid,$fseq,$fplus,$fscore);
while(<IN>) {

	$id = $_;
	$seq=<IN>;
	$plus=<IN>;
	$score=<IN>;
	chomp($id);

	if($id =~ m/\.r/) {
		$id =~ s/\.r//; 

		my $next = <IN>;
		if ($next =~ m/$id\.f/) {
			$fid = $next;
			chomp($fid);
			$fid =~ s/\.f//; 
			$fseq=<IN>;
			$fplus=<IN>;
			$fscore=<IN>;
		
			print OUT1 $fid."/1\n".$fseq."+\n".$fscore;
			print OUT2 $id."/2\n".$seq."+\n".$score;
		}
		else {
			seek(IN, -length($next), 1);
			print OUT3 $id."/2\n".$seq."+\n".$score;
		}
	}
	else {
		$id =~ s/\.\w+//;
		print OUT3 $id."/1\n".$seq."+\n".$score;
	}
}
close(OUT1);
close(OUT2);
close(OUT3);
close(IN);

$time = time - $time;
print "Time elapsed: $time sec.\n";
