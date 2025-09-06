#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# assignToHaplotypeBlocks.pl
# written by Linnéa Smeds                      14 July 2015
# ---------------------------------------------------------
# DESCRIPTION:
# Takes a combined parent-offspring file with haplotypes and
# nucleotides, and a file with the different block regions.
# Then adds a column to the first file with the name of the 
# block.
#
# Infile1
# Chr1	103066	A	T	0|0	1|1	1|0	1|0	0|0	1|0	Pat
# Chr1	105372	C	A	1|1	0|0	0|1	0|1	0|0	0|0	Pat
# Chr1	108210	G	C	1|1	0|0	0|1	0|1	0|0	0|0	Mat
#
# Infile2 (not bed! Just standard pos!)
# Chr1	6000	2522238		Pat	2924
# Chr1	2523587	20109012	Mat	38481
#
# Outfile 
# Chr1	103066	A	T	0|0	1|1	1|0	1|0	0|0	1|0	Pat	Pat
# Chr1	105372	C	A	1|1	0|0	0|1	0|1	0|0	0|0	Pat	Pat
# Chr1	108210	G	C	1|1	0|0	0|1	0|1	0|0	0|0	Mat	Pat
# ---------------------------------------------------------
# Example 

use strict;
use warnings;

# Input parameters
my $FILE = $ARGV[0];
my $BLOCKS = $ARGV[1];


# SAVE THE BLOCKS
my %hash = (); 
open(IN, $BLOCKS);
while(<IN>){
	my @a = split(/\s+/, $_);
	$hash{$a[0]}{$a[1]}{'end'}=$a[2];
	$hash{$a[0]}{$a[1]}{'state'}=$a[3];
}
close(IN);


# GO THROUGH THE FILE
open(IN, $FILE);
my ($chr,$state,$snpcnt,$start,$end) = ("","", 0, 0, 0, 0);
my $linecnt=0;
my $snpsum=0;

while(<IN>) {
	my @t=split(/\s+/, $_);
	chomp($_);
	my $state="Unknown";
	foreach my $key (sort {$a<=>$b} keys %{$hash{$t[0]}}) {
		if($key<=$t[1] && $t[1]<=$hash{$t[0]}{$key}{'end'}) {
			#Found the block!
			$state=$hash{$t[0]}{$key}{'state'};
			last;
		}	
	}	
	
	print $_."\t".$state."\n";	
}
close(IN);

