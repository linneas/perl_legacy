#!/usr/bin/perl

# addAAInfoToVCF.pl  	
# written by Linnéa Smeds,                  17 Oct 2016
# =====================================================
# Takes a vcf file and a fasta file with ancestral 
# alleles, and adds this to the vcf INFO column for 
# each position.
#
# NOTE: The module samtools needs to be loaded! 
# =====================================================
# usage perl addAAInfoToVCF.pl file.vcf anc.fa new.vcf

use strict;
use warnings;

# INPUT PARAMETERS
my $VCFFILE = $ARGV[0];	# The vcf file with all positions
my $FASTA = $ARGV[1]; 	# Ancestral fasta file
my $OUT = $ARGV[2];		# The new vcf file

# Starting clock
my $time = time;

# OPEN FILE HANDLE TO OUTPUT FILE
open(OUT, ">$OUT");


# Open FILE HANDLE TO INPUT FILE
my $cnt=0;
open(IN, $VCFFILE);
while(<IN>) {
	# Found the first INFO line
	if(/^##INFO/)	{
		print OUT $_;
		
		#Loop through all lines starting with ##INFO
		my $next = <IN>;
		while ($next =~ m/^##INFO/) {	
			print OUT $next;
			$next=<IN>;
		}
		#Outside of the loop-> found a line that didn't start with INFO.	
		#Print the extra info line (and the other line)
		print OUT "##INFO=<ID=AA,Number=1,Type=String,Description=\"Ancestral Allele\">\n";
		print OUT $next;
	}
	# Any other type of header line, just print
	elsif(/^#/) {
		print OUT $_;
	}
	# Anything that doesn't start with "#" -> a variant!
	else {		
	
		my @tab=split(/\s+/, $_);
		my $scaf=$tab[0];
		my $pos=$tab[1];

		# Run an external command from perl using "backtick operator" ("`")
		my $anc=`samtools faidx $FASTA $scaf:$pos-$pos |tail -n1`; #get the ancestral base
 		
		chomp($anc);	#This line removes any tailing "\n" 
		
		$tab[7]=$tab[7].";AA=$anc";		#This line adds the ancestral allele to the info column

		print OUT join("\t", @tab)."\n";
		$cnt++;

	}
}
close(IN);
close(OUT);

print "Processed $cnt variants\n";
$time = time-$time;
if($time<60) {
	print "Total time elapsed: $time sec.\n";
}
else {
	$time = int($time/60 + 0.5);
	print "Total time elapsed: $time min.\n";
}

