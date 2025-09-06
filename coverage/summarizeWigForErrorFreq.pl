#!/usr/bin/perl

my $usage="
# # # # # #
# summarizeWigForErrorFreq.pl
# written by Linnéa Smeds                   29 Jan 2015
# =====================================================
# Takes a wigfile (from IGVtools) and a vcf file with
# known variant sites, and checks how many non-ref and
# non-alt reads there are for a given position (these
# MUST be wrong, and can therefore be used to estimate
# error frequencies).
#
# INPUT:
# 1) .wig-file: (from IGVtools)
# 2) .vcf-file: (with variants, preferably for the same
				 regions as the wig file)
  3) wig type:	\"multi\" (standard wig file) or
			    \"single\" (for one scaffold wif files)
  4) out-file:	Name of output file
  5) scaffold:  ONLY when wig type is set as single
# =====================================================
# USAGE: perl summarizeWigForErrorFreq.pl genome.wig \
#			variants.vcf multi myresult.txt
# OR:	 perl summarizeWigForErrorFreq.pl scaf1.wig \
#			scaf1_variants.vcf single myresult.txt scaf1
#
";


use strict;
use warnings;
use List::Util qw[min max];
#use Statistics::Basic qw(:all nofill);

# Input parameters
my $WIGFILE = $ARGV[0];
my $VCFFILE = $ARGV[1];
my $WIGTYPE = $ARGV[2];	#Must be single or multi
my $OUT = $ARGV[3];
my $SCAFFOLD = $ARGV[4];

unless($WIGTYPE eq "single" || $WIGTYPE eq "multi") {
	die "Type must be specified for the wig file: multi|single.\n If single, scaffold name must be given as extra input.\n $usage\n";

}
if($WIGTYPE eq "single") {
	unless (defined $SCAFFOLD) {
		die "When wig type is set to single, scaffold name must be given as 5th output.\n $usage\n";
	}
}


# Open outfiles
open(OUT, ">$OUT");
print OUT "SCAFFOLD\tPOSITION\t#REF(BASE)\t#ALT(BASE)\t#THIRD(BASE)\tTOTAL\tTHIRD_RATIO\tERROR_RATIO\n";



# Save positions
my %pos = ();
open(VCF, $VCFFILE);
while(<VCF>) {
	unless(/^#/) {
		my @F=split(/\t/,$_);

		if($WIGTYPE eq "single" && $F[0] ne $SCAFFOLD) {
			next;
		}
		 	
		# Check if any of the variants are longer than 1 bp (indels)
		# Or if the site is triallelic (like A,T - meaning no clear alt)
		my $use = 0; 
		if (length($F[3]) > 1 || length($F[4]) > 1){
			$use++;
		}
		# We don't want indel or multiple-allele sites, so save only if there are no indels		
		if ($use == 0){
			$pos{$F[0]}{$F[1]}{'ref'}=$F[3];
			$pos{$F[0]}{$F[1]}{'alt'}=$F[4];
		}
	}
}
close(VCF);

my %col = ('A'=>1, 'C'=>2, 'G'=>3, 'T'=>4);

# Go through the wig file 
open(IN, $WIGFILE);
<IN>; <IN>;	# Skip two header lines
while(<IN>) {
	my @F = split(/\s+/,$_);

	my ($ref, $alt, $third, $allerr, $tot) = (0,0,0,0,0);
	my $thirdbase="";
	
	if($WIGTYPE eq "single") { # Need to separate the two cases
		if(defined $pos{$SCAFFOLD}{$F[0]}) {
			$ref=$F[$col{$pos{$SCAFFOLD}{$F[0]}{'ref'}}];
			$alt=$F[$col{$pos{$SCAFFOLD}{$F[0]}{'alt'}}];
			my ($tempbig, $tempbigno)=("",-1);
			foreach my $key (keys %col) {
				 $tot+=$F[$col{$key}];
				unless ($key eq $pos{$SCAFFOLD}{$F[0]}{'ref'} || $key eq $pos{$SCAFFOLD}{$F[0]}{'alt'}) {
					$allerr+=$F[$col{$key}];
					if($F[$col{$key}]>$tempbigno) {
						$tempbigno=$F[$col{$key}];
						$tempbig=$key;
					}
				}
			}
			$third=$tempbigno;
			$thirdbase=$tempbig;

			my ($thirdrate,$errate)=("NA","NA");

			if($tot>0) {
				$thirdrate=$third/$tot;
			 	$errate=$allerr/$tot;
			}
	
			print OUT $SCAFFOLD."\t".$F[0]."\t".$ref."(".$pos{$SCAFFOLD}{$F[0]}{'ref'}.")\t".$alt."(".
					$pos{$SCAFFOLD}{$F[0]}{'alt'}.")\t".$third."(".$thirdbase.")\t".$tot."\t".
					$thirdrate."\t".$errate."\n";


		}

	}

	
}
close(IN);
















