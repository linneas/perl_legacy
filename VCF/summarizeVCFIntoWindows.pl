#!/usr/bin/perl

my $usage = "
# summarizeVCFIntoWindows.pl  	
# written by Linnéa Smeds		  		   1 Jan 2020
# complete remake of old script (from 30 March 2012) 
# with same name, that saved all positions in a hash and
# demanded an additional file with a list of windows.
# This one takes seconds instead of hours for mammal 
# sized genome!
# =====================================================
# Takes a VCF file (or any kind of file with scaff/chrom
# in first column), a list of chromosomes with sizes
# and a wanted window size, and summarizes the number 
# of SNPs (or rows) per window.
#
# NB! Only list full windows - end of chr/scaff shorter
# than the window size is not printed. 
# NB2! VCF file needs to be SORTED.
# NB3! If the vcf file contains a position that is larger
# than the given chromosome size, this script will enter
# an infinite loop!
# =====================================================
# usage perl summarizeVCFIntoWindows.pl -vcf=file.vcf -chr=chrlen.txt -ws=50000 -out=file.50kb.summary.txt
";

use strict;
use warnings;
use Getopt::Long;
use List::Util qw[min max];


my ($VCF,$CHR,$WS,$HELP,$OUT);
GetOptions(
  	"vcf=s" => \$VCF,
	"chr=s" => \$CHR,
   	"ws=i" => \$WS,
	"h" => \$HELP,
	"out=s" => \$OUT);

#--------------------------------------------------------------------------------
#Checking input, set default if not given
unless(-e $VCF) {
	die "Error: File $VCF doesn't exist!\n";
}
unless(-e $CHR) {
	die "Error: File $CHR doesn't exist!\n";
}

unless($WS) {
	die "Error: Window size was not given!\n";
}
if($HELP) {
	die $usage . "\n";
}
#--------------------------------------------------------------------------------
print STDERR "Summarize $VCF in windows of size $WS\n";
if($OUT) {
	open(OUT, ">$OUT");
} 
else{
	print STDERR "Print output to stdout!\n";
}

# Add list of chromosomes and sizes to hash
open(IN, $CHR);
my %chroms = ();
while(<IN>) {
		my @tab = split(/\s+/, $_);
		$chroms{$tab[0]}=$tab[1];
}
close(IN);

#print "DEBUG: windowsize is now $WS\n";

# Go through positions and windows simultaneously
my $c=0;
my $wc=0;
my $cstart=0;
my $cend=$WS;
my $chr="";
my $prints="";
open(IN, $VCF);
while(<IN>) {
	unless(/^#/) {
		my @tab=split(/\s+/, $_);
		unless($chr eq $tab[0]) {	#New chromosome, start all over and print old 
#			print "DEBUG: we have a new chromosome!\n";

			if($c==0) {	#first line, don't print
#				print "BEBUG: First line, nothing saved to print\n";
			}
			else {		# Not first line, add last window to last chr and print
#				print "DEBUG: There is something to print! First add chr $chr, cstart $cstart, cend $cend and wc $wc!\n";
				$prints.=$chr."\t".$cstart."\t".$cend."\t".$wc."\n";

				if($OUT) {
					print OUT $prints;
				}
				else {
					print $prints;
				}
				$prints="";
				$cstart=0;
				$cend=min($WS,$chroms{$chr});
				$wc=0;
				$chr=$tab[0];
			}

			$chr=$tab[0];

		}

		if($tab[1]>$cend) {	# position lies outside this window
			# loop until we are inside a window
			while($tab[1]>$cend) {	#if there are more empty windows	
				$prints.=$chr."\t".$cstart."\t".$cend."\t".$wc."\n";
				my $tmp=$cend+$WS;
				$cstart=$cend;
				$cend=min($tmp, $chroms{$chr});
				$wc=0;
			}
		}
		$wc++;
		$c++;
	}
}
#afterwards print last (unprinted) chromosome
$prints.=$chr."\t".$cstart."\t".$cend."\t".$wc."\n";
if($OUT) {
	print OUT $prints;
}
else {
	print $prints;
}
print "Done! Went through $c positions!\n";
close(IN);

