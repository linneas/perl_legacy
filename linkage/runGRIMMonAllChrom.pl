#!/usr/bin/perl


# # # # # #
# runGRIMMonAllChrom.pl
# written by Linnéa Smeds                    Nov 2012
# ===================================================
# Run GRIMM on a all chromosomes on a list, takes the
# m-pararameter, g-parameter and a path to grimm and
# karyotype input files.
# ===================================================
# Usage: 

use strict;
use warnings;
use List::Util qw(max min);

# Input parameters
my $CHROMLIST = $ARGV[0];
my $m = $ARGV[1];
my $g = $ARGV[2];
my $PathToInput = $ARGV[3];

# Other parameters
my $ancDir = "anchors";
my $blockDir = "blocks";
my $SCAFFLIST = "/proj/b2010010/private/Linkage/fAlb15_chromosomes_allWithLinksToCertain_20121009.txt";
my $REPEAT = "/proj/b2010010/private/igv/annotations/fAlb15_repeatMasker.bed";
my $ASSEMBLY = "/proj/b2010010/private/assembly/fAlb15.fa.masked";
my $PATH = "/bubo/home/h14/linnea/private/scripts/";
my $edge = "10kb";

#Outfile
my $OUT = "summaryBreaks_m".$m.".g".$g.".txt";
open(OUT, ">$OUT");
print OUT "#CHROM	BREAKS	MEANSIZE	REPEATS	GCCONT Ns\n";
my $OUT2 = "summaryEdge_m".$m.".g".$g.".txt";
open(OUT2, ">$OUT2");
print OUT2 "#CHROM	EDGES	MEANSIZE	REPEATS	GCCONT Ns\n";

# Create GRIMM working directories
system("mkdir -p $ancDir/");
system("mkdir -p $blockDir/");		

open(IN, $CHROMLIST);
while(<IN>) {
	my $chrom = $_;
	chomp($chrom);
	$chrom =~ m/chr(.+)/;
	my $chrNo = $1;
	my $prefix = "block.$chrom.m$m.g$g";

	print "Looking at $chrNo\n";

	my $karyotype = $PathToInput."karyo.$chrom.col.comb.txt";
	my $grimmInput = $PathToInput."grimm.$chrom.txt";
	my $ancRepeat =	"$ancDir/repeat_coords.$chrom.txt";
	my $ancUniq = "$ancDir/unique_coords.$chrom.txt";
	my $ancReport = "$ancDir/report_ga.$chrom.txt";
	my $blBlock = "$blockDir/blocks.$chrom.m$m.g$g.txt";
	my $blMacro = "$blockDir/mgr_macro.$chrom.m$m.g$g.txt";
	my $blMicro = "$blockDir/mgr_micro.$chrom.m$m.g$g.txt";
	my $blMicEqv = "$blockDir/mgr_micro_equiv.$chrom.m$m.g$g.txt";
	my $blReport = "$blockDir/report.$chrom.m$m.g$g.txt";

	# Make anchor files
	system("~/glob/software/GRIMM_SYNTENY-2.02/grimm_synt -A -f $grimmInput -d $ancDir");

	# Make block files
	system("~/glob/software/GRIMM_SYNTENY-2.02/grimm_synt -f $ancDir/unique_coords.txt -d $blockDir -c -p -m $m -g $g");
	
	# Calculate some stuff
	my $breakfile = $prefix."_rearrRegions.txt";
	my $blockfile = $prefix."_SortedBlocks.txt";
	my $edgefile = $prefix."_Edge".$edge.".txt";
 	system("perl $PATH/linkage/findBlocksFromGRIMM.pl $blockDir/blocks.txt $karyotype $SCAFFLIST $prefix");
	my $no = `wc -l $blockfile|awk '(FS=\" \"){print \$1}'`;
	chomp($no);
	$no-=2;
	my ($fracN, $fracRep, $fracGC, $meanlen, $ED_fracN, $ED_fracRep, $ED_fracGC, $ED_meanlen) = ("-","-","-","-","-","-","-","-");
	#If there are at least one break
	if($no>0) {
		my $breakFasta = $prefix."_break.fa";
		my $edgeFasta = $prefix."_edge$edge.fa";
		# Breaks
		my $repbases = `intersectBed -a $breakfile -b $REPEAT | awk '{sum+=\$3-\$2+1}END{print sum}'`;
		system("perl $PATH/fasta/extractPartOfFastaMult.pl $ASSEMBLY $breakfile >$breakFasta");
		my $Nbases = `perl $PATH/fasta/NDistrFromFasta.pl $breakFasta fast|head -n1 |awk '(FS=" "){print \$5}'`;
		my $GCbases = `perl $PATH/fasta/GCDistrFromFasta.pl $breakFasta fast|head -n1 |awk '(FS=" "){print \$5}'`;
		my $length = `awk '{sum+=\$3-\$2+1}END{print sum}' $breakfile`;	
		chomp($Nbases);
		chomp($repbases);
		chomp($GCbases);
		chomp($length);
		#Edges
		my $ED_repbases = `intersectBed -a $edgefile -b $REPEAT | awk '{sum+=\$3-\$2+1}END{print sum}'`;
		system("perl $PATH/fasta/extractPartOfFastaMult.pl $ASSEMBLY $edgefile >$edgeFasta");
		my $ED_Nbases = `perl $PATH/fasta/NDistrFromFasta.pl $edgeFasta fast|head -n1 |awk '(FS=" "){print \$5}'`;
		my $ED_GCbases = `perl $PATH/fasta/GCDistrFromFasta.pl $edgeFasta fast|head -n1 |awk '(FS=" "){print \$5}'`;
		my $ED_length = `awk '{sum+=\$3-\$2+1}END{print sum}' $edgefile`;	
		chomp($ED_Nbases);
		chomp($ED_repbases);
		chomp($ED_GCbases);
		chomp($ED_length);
		
		($fracN, $fracRep, $fracGC, $meanlen) = ($Nbases/$length, $repbases/$length, $GCbases/$length, int($length/$no+0.5));
		($ED_fracN, $ED_fracRep, $ED_fracGC, $ED_meanlen) = ($ED_Nbases/$ED_length, $ED_repbases/$ED_length, $ED_GCbases/$ED_length, int($ED_length/(2*$no)+0.5));
	}

	print OUT $chrom."\t".$no."\t".$meanlen."\t".$fracRep."\t".$fracGC."\t".$fracN."\n";
	print OUT2 $chrom."\t".$no."\t".$ED_meanlen."\t".$ED_fracRep."\t".$ED_fracGC."\t".$ED_fracN."\n";

	
	# Rename the files to avoid overwriting
	system("mv $ancDir/repeat_coords.txt $ancRepeat");
	system("mv $ancDir/unique_coords.txt $ancUniq");
	system("mv $ancDir/report_ga.txt $ancReport");
	system("mv $blockDir/blocks.txt $blBlock");
	system("mv $blockDir/mgr_macro.txt $blMacro");
	system("mv $blockDir/mgr_micro.txt $blMicro");
	system("mv $blockDir/mgr_micro_equiv.txt $blMicEqv");
	system("mv $blockDir/report.txt $blReport");
}
close(IN);
