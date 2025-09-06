#!/usr/bin/perl


# # # # # #
# extractAllBreakpointInfo.pl
# written by Linnéa Smeds                    Jan 2013
# ===================================================
# Takes a list of regions (breakpoints) with chrom,
# start and stop and extracts the sequences from the
# original fasta files (which must be placed in a 
# folder named after the species, where each chrom is
# named with species and chromosome number (no space)
# with the extention ".fasta". From the extracted 
# sequences both repeat content, GC, Ns and the
# number of 5kb gaps (scaffold junctions) on fa are
# calculated and printed to a summary table.
# ===================================================
# Usage: 

use strict;
use warnings;
use List::Util qw(max min);

# Input parameters
my $BREAKLIST = $ARGV[0];
my $CHROMLIST = $ARGV[1];
my $SP = $ARGV[2];
my $OUTPREFIX = $ARGV[3];

# Other parameters
my $ancDir = "anchors";
my $blockDir = "blocks";
my $PATH = "/bubo/home/h14/linnea/private/scripts/";
my ($REPEAT, $GENOMEPATH, $PREF, $SUFF, $CHRPRF, $GAPWARN) = ("","","","","","-");
if($SP eq "fa") {
	$REPEAT = "/proj/b2010010/private/igv/annotations/fAlb15catChrom_gap5kb_repeatmasker.bed";
	$GENOMEPATH = "/proj/b2010010/private/assembly/fAlb15_concat/strict_softMasked_gap5kb/";
	$PREF = "fAlb15_chr";
	$SUFF = ".fa.softmasked";
	$CHRPRF = "Chr";
	$GAPWARN = 5000;
}
elsif($SP eq "tg") {
	$REPEAT = "/bubo/home/h14/linnea/glob/RefGenomes/TaeGut.3.2.4.59_homemade_repeat.bed";
	$GENOMEPATH = "/bubo/nobackup/uppnex/reference/Taeniopygia_guttata/taeGut3.2.4/chromosomes/";
	$PREF = "Taeniopygia_guttata.taeGut3.2.4.59.dna.chromosome.";
	$SUFF = ".fa";
}
elsif($SP eq "gg") {
	$REPEAT = "/bubo/home/h14/linnea/glob/RefGenomes/GalGal.WASHUC2.57_homemade_repeat.bed";
	$GENOMEPATH = "/bubo/nobackup/uppnex/reference/Gallus_gallus/WASHUC2/chromosomes/";
	$PREF = "Gallus_gallus.WASHUC2.57.dna.chromosome.";
	$SUFF = ".fa";
}
else {
	die "There is no repeat file for $SP!";
}


#Outfile(s)
my $OUTSUM = $OUTPREFIX.".summary.txt";
open(OUT, ">$OUTSUM");
print OUT "#CHROM	BREAKS	MEANSIZE	REPEATS	GCCONT Ns	5kbGAPS\n";

# Whole genome summary (save data in hash)
my %totsum = ("Total", 0, "Breaks", 0, "Repeats", 0, "GC", 0, "Ns", 0, "Gap5kb", 0);

# Save chromosomes
my $tempfile = "breaks.tmp";
my $allchromFile = $SP.".breakpoints.bed";
system("rm -f $allchromFile");

open(IN, $CHROMLIST);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	my $chrNo = $tab[0];
	my $spchrom = lc($chrNo);

	$chrNo =~ s/$SP//;
	$chrNo = uc($chrNo);
	my $chrom = $CHRPRF.$chrNo;

#	print "DEBUG: Looking at ".$chrom."\n";

	my $GENOME = $GENOMEPATH."/".$PREF.$chrNo.$SUFF;
#	print "DEBUG: Extracting from $GENOME\n";
	my $breakFasta = $tab[0]."_breaks.fa";

	#Extracting the lines for each chromosome
#	print "DEBUG: checking for rows which start with $spchrom from file $BREAKLIST\n";
	system("awk '(\$1==\"$spchrom\"){print \"$chrom\t\"\$2\"\t\"\$3}' $BREAKLIST >$tempfile");
	my $no = `wc -l $tempfile |awk '(FS=\" \"){print \$1}'`;
	chomp($no);
#	print "DEBUG: No is $no\n";
	my ($fracN, $fracRep, $fracGC, $meanlen, $warn) = ("-","-","-","-","-");

	#Extract fasta sequences (if there are any breaks) and calc len, GC repeats etc
	if($no>0) {

		system("cat $tempfile >>$allchromFile");

		#Check repeat with intersectBed
		my $repbases = `awk '{if(\$3<\$2){print \$1\"\t\"\$3\"\t\"\$2\"\t\"\$4}else{print}}' $REPEAT | intersectBed -a $tempfile -b - | awk '{sum+=\$3-\$2+1}END{print sum}'`;
		system("perl $PATH/fasta/extractPartOfFastaMult.pl $GENOME $tempfile >$breakFasta");

		#Check Ns
		my $Nrow = `perl $PATH/fasta/NDistrFromFasta_specialSizeWarning.pl $breakFasta fast $GAPWARN|head -n1 `;
		my @splitNrow = split(/\s+/, $Nrow); 
		my $Nbases = $splitNrow[4];
		if($splitNrow[11]) {
			$warn = $splitNrow[11];
			$totsum{"Gap5kb"}+=$warn;
		}
		my $GCbases = `perl $PATH/fasta/GCDistrFromFasta.pl $breakFasta fast|head -n1 |awk '(FS=" "){print \$5}'`;
		my $length = `awk '{sum+=\$3-\$2+1}END{print sum}' $tempfile`;	
		chomp($Nbases);
		chomp($repbases);
		chomp($GCbases);
		chomp($length);

		$totsum{"Total"}+=$length;
		$totsum{"Breaks"}+=$no;
		$totsum{"Repeats"}+=$repbases;
		$totsum{"GC"}+=$GCbases;
		$totsum{"Ns"}+=$Nbases;
	
		($fracN, $fracRep, $fracGC, $meanlen) = ($Nbases/$length, $repbases/($length-$Nbases), $GCbases/($length-$Nbases), int($length/$no+0.5));
	}
	print OUT $chrom."\t".$no."\t".$meanlen."\t".$fracRep."\t".$fracGC."\t".$fracN."\t".$warn."\n";
	

}
close(IN);

# Genome wide summary:
my $totRepFrac = $totsum{"Repeats"}/($totsum{"Total"}-$totsum{"Ns"});
my $totGCFrac = $totsum{"GC"}/($totsum{"Total"}-$totsum{"Ns"});
my $totNFrac = $totsum{"Ns"}/$totsum{"Total"};
my $totGaps = "-";
if($totsum{"Gap5kb"}>0) {
	$totGaps = $totsum{"Gap5kb"}
}

print "Total number of breakpoints: ".$totsum{"Breaks"}."\n";
print "Total number of bp in breakpoints: ".$totsum{"Total"}."\n";
print "Repeat fraction (outside Ns): ".$totRepFrac."\n";
print "GC fraction (outside Ns): ".$totGCFrac."\n";
print "N fraction: ".$totNFrac."\n";
print "Scaffold junctions: ".$totGaps."\n";

