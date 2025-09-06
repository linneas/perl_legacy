#!/usr/bin/perl

# # # # #
# divideFastaFile.pl        
# written by Linnéa Smeds 		       3 July 2013
# ========================================================
# Takes a fasta file and divides it into several files with
# a given maximun number of sequences in each file.
# ========================================================
# usage perl divideFastaFile.pl <fasta> <no> <outpref> <outdir>    
# example perl divideFastaFile.pl file.fa 5 file_divided .

use strict;
use warnings;

my $time = time;

# Input parameters
my $fasta = $ARGV[0];
my $seqPerFile = $ARGV[1];
my $prefix = $ARGV[2];
my $outDir = $ARGV[3];


my $wcLine = `grep ">" $fasta |wc`;
my @a = split(/\s+/, $wcLine);
my $seqNo = $a[1]; 
my $cnt = 0;
print "Total number of seq is $seqNo\n";

# Number of files:
my $noOfFiles=int($seqNo/$seqPerFile+0.9999);
print "Start printing to $noOfFiles files.\n";

# Loop over output files, open input first
open(FAS, $fasta);
for (my $i=0; $i<$noOfFiles; $i++) {
	my $start=$i*$seqPerFile+1;
	my $end = $start+$seqPerFile-1;	
	if($end>$seqNo) {
		$end=$seqNo;
	}
	my $out = $prefix."_".$start."_".$end.".fa";
	open(OUT, ">$out");

	my $cnt=0;
	my $printflag="on";

	# Loop through fasta file until X sequences are found
	# WITHOUT closing the file afterwards (opens on the same
	# place next time)
	while(my $line=<FAS>) {
		if($line =~ m/^>/) {
			$cnt++;
			# When we find the first seq of the new file, 
			# put it back in the stream and abort while
			if($cnt==($seqPerFile+1)) {
				seek(FAS, -length($line), 1);
				last;
			}
			else {
				print OUT $line;
			}
		}
		else {
			print OUT $line;
		}
	}
	close(OUT);
}
close(FAS);


