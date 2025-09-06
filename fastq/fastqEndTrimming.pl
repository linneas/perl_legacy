#!/usr/bin/perl

# fastqEndTrimming.pl
# September 2010, mod Jan 2011
# Author: Linnéa Smeds (linnea.smeds@ebc.uu.se)

use strict;
use warnings;
use Getopt::Long;


my $usage = "# fastqEndTrimming.pl
# September 2010, mod Jan 2011
# Author: Linnéa Smeds (linnea.smeds\@ebc.uu.se)
# -------------------------------------------------------------------------------
# Description: Trim reads from the 3'-end and extract reads (or read pairs) of
# good quality. If the reads are paired, the filtering is done pairwise, and 
# if one read in a pair has low quality, the remaning read is saved as single end.
# Usage: perl fastqEndTrimming.pl -fastq1=file1 [-fastq2=file2 
#			-prefix=s -hq=N -lq=N -frac=N -minlen=N -mh=N -ml=N -sc=N]

-fastq1=file \t Fastq file. If a second file is given, the files are trimmed
-fastq2=file \t as a pair. The reads must have the same order in both files.
-prefix=string \t Prefix for the output file(s). The filtered fastq file(s) will
 \t\t be named prefix_trim1.fastq (and prefix_trim2.fastq if present). For pairs,
 \t\t a third file will be given with unpaired reads (reads from pairs where one 
 \t\t low quality read has been removed).
-hq=N \t\t Hiqh quality threshold [25].
-lq=N \t\t Low quality threshold [10].
-frac=[0,1]\t Fraction of read that must exceed hq [0.8].
-minlen=N \t Min allowed read length [50].
-mh=N \t\t When this no of sequential hq bases is reached, the trimming stops [5].
-ml=N \t\t Max no of lq bases allowed after a stretch of hq bases from 3'-end [1].
-sc=N\t\t Illumina scoring table, Score=ASCII-sc, usually 64, 33 in old pipe. [64].
-q \t\t Print Illumina scoring table.
-h \t\t Print this help message.\n";
		
# Starting time
my $time = time;

# Input parameters
my ($read1,$read2,$prefix,$HQlim,$lowlim,$minfrac,$minReadLen,$maxNoHQ,$maxNoLQ,$scoring,$tbl,$help);
GetOptions(
  	"fastq1=s" => \$read1,
   	"fastq2=s" => \$read2,
  	"prefix=s" => \$prefix,
  	"hq=i" => \$HQlim,
	"lq=i" => \$lowlim,
	"frac=s" => \$minfrac,
	"minlen=i" => \$minReadLen,
	"mh=i" => \$maxNoHQ,
   	"ml=i" => \$maxNoLQ,
	"sc=i" => \$scoring,
	"q" => \$tbl,
	"h" => \$help);
	

#--------------------------------------------------------------------------------
#Checking input, set default if not given
if($tbl) {
	&table();
	exit;
}
unless($read1) {
	die $usage . "\n";
}
if($help) {
	die $usage . "\n";
}
unless($prefix) {
	$prefix = $read1;
	$prefix =~ s/\.\w+//;
}
unless($HQlim) {
	$HQlim=25;
}
unless($lowlim) {
	$lowlim=10;
}
if($minfrac) {
	if($minfrac<0 || $minfrac>1) {
		die "Error: frac must be between 0 and 1.\n";
	}
}
else{
	$minfrac=0.8;
}
unless($maxNoHQ) {
	$maxNoHQ=5;
}
unless($maxNoLQ) {
	$maxNoLQ=1;
}
unless($minReadLen) {
	$minReadLen=50;
}
unless($scoring) {
	$scoring=64;
}
unless(-e $read1) {
	die "Error: File $read1 doesn't exist!\n";
}
print "\nfastqEndTrimming.pl started " . localtime() . "\n";
print "------------------------------------------------------------------\n";

my ($totNoReads, $pairReads, $unpairedReads) = (0,0,0);
my ($totNoBases, $pairBases, $unpairedBases) = (0,0,0);
#--------------------------------------------------------------------------------
# Trimming paired files
if($read2) {
	unless(-e $read2) {
		die "Error: File $read2 doesn't exist!\n";
	}
	my $out1 = $prefix . "_trim1.fastq";
	my $out2 = $prefix . "_trim2.fastq";
	my $out3 = $prefix . "_trim_unpaired.fastq";
	open(IN1, $read1);
	open(IN2, $read2);
	open(OUT1, ">$out1");
	open(OUT2, ">$out2");
	open(OUT3, ">$out3");
	my($head1,$seq1,$plus1,$qual1,$head2,$seq2,$plus2,$qual2);
	print "Processing...\n";

	while(my $line = <IN1>) {
		$head1 = $line;
		chomp($seq1 = <IN1>);
		$plus1 = <IN1>;
		chomp($qual1 = <IN1>);
		
		$head2 = <IN2>;
		chomp($seq2 = <IN2>);
		$plus2 = <IN2>;
		chomp($qual2 = <IN2>);
		
		# Trim both reads
		my($newseq1, $newscore1) = &trimEnd($seq1,$qual1, $HQlim, $lowlim, $maxNoHQ, $maxNoLQ, $minReadLen, $scoring);
		my($newseq2, $newscore2) = &trimEnd($seq2,$qual2, $HQlim, $lowlim, $maxNoHQ, $maxNoLQ, $minReadLen, $scoring);

		# Check if reads are ok, print good reads
		if(readOK($newscore1, $HQlim, $lowlim, $minfrac, $scoring)) {
			if(&readOK($newscore2, $HQlim, $lowlim, $minfrac, $scoring)) {
				print OUT1 $head1 . $newseq1 ."\n" . $plus1 . $newscore1 . "\n";
				print OUT2 $head2 . $newseq2 ."\n" . $plus2 . $newscore2 . "\n";
				$pairReads+=2;
				$pairBases+=length($newseq1)+length($newseq2);
			}
			else {
				print OUT3 $head1 . $newseq1 ."\n" . $plus1 . $newscore1 . "\n";
				$unpairedReads++;
				$unpairedBases+=length($newseq1);
			}
		}
		else {
			if(&readOK($newscore2, $HQlim, $lowlim, $minfrac, $scoring)) {
				print OUT3 $head2 . $newseq2 ."\n" . $plus2 . $newscore2 . "\n";
				$unpairedReads++;
				$unpairedBases+=length($newseq2);
			}
		}
		$totNoBases+=length($seq1)+length($seq2);
		$totNoReads+=2;
		if ($totNoReads%100000==0) {
			print "$totNoReads reads processed\r";
		}
	}
}
# Trimming single end files
else {
	my $out1 = $prefix . "_trim1.fastq";
	open(IN1, $read1);
	open(OUT1, ">$out1");	
	print "Processing...\n";
	my($head1,$seq1,$plus1,$qual1);

	while(my $line = <IN1>) {
		$head1 = $line;
		chomp($seq1 = <IN1>);
		$plus1 = <IN1>;
		chomp($qual1 = <IN1>);
		
		my($newseq1, $newscore1) = &trimEnd($seq1,$qual1, $HQlim, $lowlim, $maxNoHQ, $maxNoLQ, $minReadLen, $scoring);
		if(readOK($newscore1, $HQlim, $lowlim, $minfrac, $scoring)) {
			print OUT1 $head1 . $newseq1 ."\n" . $plus1 . $newscore1 . "\n";
			$unpairedReads++;
			$unpairedBases+=length($newseq1);
		}
		$totNoBases+=length($seq1);
		$totNoReads+=1;
		if ($totNoReads%100000==0) {
			print "$totNoReads reads processed\r";
		}
	}
	
}

#--------------------------------------------------------------------------------
# Print statistics to table
open(STATS, ">$prefix".".stats");
print STATS $prefix."\t".$totNoReads."\t".$totNoBases."\t".$pairReads."\t".$pairBases.
		"\t".$unpairedReads."\t".$unpairedBases."\n";

print "\nDone!\n";
print "------------------------------------------------------------------\n";
if($read2) {
	print "$totNoReads reads with $totNoBases bases in input files\n";
	my $percent = 100*($pairReads/$totNoReads);
	print "$pairReads ($percent%) reads with $pairBases bases saved in pair files\n";
	$percent = 100*($unpairedReads/$totNoReads);
	print "$unpairedReads ($percent%) reads with $unpairedBases bases saved in unpaired file\n";
	print "  due to low quality of the mate\n";
}
else {
	print "$totNoReads reads with $totNoBases bases in input file\n";
	my $percent = 100*($unpairedReads/$totNoReads);
	print "$unpairedReads ($percent%) reads with $unpairedBases bases saved\n";
}
print "------------------------------------------------------------------\n";
$time = time-$time;
if($time<60) {
	print "Total time elapsed: $time sec.\n";
}
else {
	$time = int($time/60 + 0.5);
	print "Total time elapsed: $time min.\n";
}

#--------------------------------------------------------------------------------
# Subroutines

sub trimEnd { 

	my $seq = shift;
	my $qual = shift;
	my $HQ = shift;
	my $LQ = shift;
	my $maxHQ = shift;
	my $maxLQ = shift;
	my $len = shift;
	my $sc = shift;

	
	my $LQ_flag = 0;
	my $HQ_warn = 0;
	my $LQinHQ_flag = "no";
	my ($qual_end, $seq_end) = ("","");

	my @t = split("", $qual);
	my @s = split("", $seq);

	while(scalar(@t)>$len && $HQ_warn<=$maxHQ) {

		if (ord($t[scalar(@t)-1])-$sc < $HQ) {
			
			if ($HQ_warn > 0 && $LQ_flag <= $maxLQ && ord($t[scalar(@t)-1])-$sc > $LQ) {
				$qual_end = pop(@t).$qual_end;
				$seq_end = pop(@s).$seq_end;
				$LQinHQ_flag = "yes";
				$LQ_flag++;

			}
			else {
				pop(@t);
				pop(@s);
				($qual_end, $seq_end) = ("","");
				$HQ_warn = 0;
			}
				
		}
		else {
			$qual_end = pop(@t).$qual_end;
			$seq_end = pop(@s).$seq_end;
			if($LQinHQ_flag eq "yes") {
				$HQ_warn = 1;
				$LQinHQ_flag = "no";
			}
			else {
				$HQ_warn++;
			}
		}
	}
	my ($newseq, $newscore)= ("","");
	$newseq = join("", @s);
	$newscore = join("", @t);
	$newscore .=$qual_end;
	$newseq .= $seq_end;
	my @results = ($newseq, $newscore);
	return @results;
}
sub readOK {

	my $qual = shift;
	my $HQ = shift;
	my $LQ = shift;
	my $frac = shift;
	my $sc = shift;
		

	my @t = split("", $qual);

	my $score_cnt=0;

	for (my $i=0; $i<scalar(@t)-1; $i++) {
		if(ord($t[$i])-$sc >= $HQ) {
			$score_cnt++;
		}
		my $tempscr = ord($t[$i])-$sc;
		if(ord($t[$i])-$sc < $lowlim) {
			return 0;
		}
	}
	if($score_cnt/scalar(@t) >= $frac) {
		return 1;
	}
	else {
		return 0;
	}
}
sub table {
print "Char	ASCII	Char-64	P(error)
;	59	-5	0.7597
<	60	-4	0.7153
=	61	-3	0.6661
>	62	-2	0.6131
?	63	-1	0.5573
@	64	0	0.5000
A	65	1	0.4427
B	66	2	0.3869
C	67	3	0.3339
D	68	4	0.2847
E	69	5	0.2403
F	70	6	0.2008
G	71	7	0.1663
H	72	8	0.1368
I	73	9	0.1118
J	74	10	0.0909
K	75	11	0.0736
L	76	12	0.0594
M	77	13	0.0477
N	78	14	0.0383
O	79	15	0.0307
P	80	16	0.0245
Q	81	17	0.0196
R	82	18	0.0156
S	83	19	0.0124
T	84	20	0.0099
U	85	21	0.0079
V	86	22	0.0063
W	87	23	0.0050
X	88	24	0.0040
Y	89	25	0.0032
Z	90	26	0.0025
[	91	27	0.0020
\	92	28	0.0016
]	93	29	0.0013
^	94	30	0.0010
_	95	31	0.0008
`	96	32	0.0006
a	97	33	0.0005
b	98	34	0.0004
c	99	35	0.0003
d	100	36	0.0003
e	101	37	0.0002
f	102	38	0.0002
g	103	39	0.0001
h	104	40	0.0001
";
}

