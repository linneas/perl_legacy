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
-h \t\t Print this help message.\n";
		
# Starting time
my $time = time;

# -------------------------------------------------------------------------------
# Input parameters
my ($read1,$read2,$prefix,$HQlim,$lowlim,$minfrac,$minReadLen,$maxNoHQ,$maxNoLQ,$scoring,$help);
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
	"h" => \$help);

# -------------------------------------------------------------------------------
#Checking input, set default if not given
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
print "uniqueFastqPairs started " . localtime() . "\n";

#--------------------------------------------------------------------------------
# Trimming file(s)

my $out1 = $prefix . "_trim1.fastq";
my $out2 = $prefix . "_trim2.fastq";
my $out3 = $prefix . "_trim_unpaired.fastq";
open(IN1, $read1);
open(OUT1, ">$out1");
my($head1,$seq1,$plus1,$qual1);
my ($head2,$seq2,$plus2,$qual2);

if($read2) {
	unless(-e $read2) {
		die "Error: File $read2 doesn't exist!\n";
	}
	open(IN2, $read2);
	open(OUT2, ">$out2");
	open(OUT3, ">$out3");
}


while(my $line = <IN1>) {
	$head1 = $line;
	chomp($seq1 = <IN1>);
	$plus1 = <IN1>;
	chomp($qual1 = <IN1>);

	# Trimming the first read	
	my $LQ_flag = 0;
	my $HQ_warn = 0;
	my $LQinHQ_flag = "no";
	my ($qual_end, $seq_end) = ("","");
	my ($firstOK, $secondOK);

	my @t = split("", $qual1);
	my @s = split("", $seq1);

	while(scalar(@t)>$minReadLen && $HQ_warn<=$maxNoHQ) {

		if (ord($t[scalar(@t)-1])-$scoring < $HQlim) {
			
			if ($HQ_warn > 0 && $LQ_flag <= $maxNoLQ && ord($t[scalar(@t)-1])-$scoring > $lowlim) {
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
	my ($newseq1, $newscore1)= ("","");
	for(@s) {
		$newseq1.=$_;
	}
	for(@t) {
		$newscore1.=$_;
	}
	$newscore1 .=$qual_end;
	$newseq1 .= $seq_end;

		
	#Check if first reads is ok
	@t = split("", $newscore1);

	my $score_cnt=0;

	for (my $i=0; $i<scalar(@t)-1; $i++) {
		if(ord($t[$i])-$scoring >= $HQlim) {
			$score_cnt++;
		}
		my $tempscr = ord($t[$i])-$scoring;
		if(ord($t[$i])-$scoring < $lowlim) {
			$firstOK = 0;
		}
	}
	if($score_cnt/scalar(@t) >= $minfrac) {
		$firstOK = 1;
		print "first read's OK!\n";
	}
	else {
		$firstOK = 0;
		print "first read's not OK!\n";
	}

	

	# Trimming the second read
	if($read2) {

		$head2 = <IN2>;
		chomp($seq2 = <IN2>);
		$plus2 = <IN2>;
		chomp($qual2 = <IN2>);

		$LQ_flag = 0;
		$HQ_warn = 0;
		$LQinHQ_flag = "no";
		($qual_end, $seq_end) = ("","");

		@t = split("", $qual2);
		@s = split("", $seq2);

		while(scalar(@t)>$minReadLen && $HQ_warn<=$maxNoHQ) {

			if (ord($t[scalar(@t)-1])-$scoring < $HQlim) {
			
				if ($HQ_warn > 0 && $LQ_flag <= $maxNoLQ && ord($t[scalar(@t)-1])-$scoring > $lowlim) {
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
		my ($newseq2, $newscore2)= ("","");
		for(@s) {
			$newseq2.=$_;
		}
		for(@t) {
			$newscore2.=$_;
		}
		$newscore2 .=$qual_end;
		$newseq2 .= $seq_end;
		
		#Check if first reads is ok
		@t = split("", $newscore2);

		my $score_cnt=0;

		for (my $i=0; $i<scalar(@t)-1; $i++) {
			if(ord($t[$i])-$scoring >= $HQlim) {
				$score_cnt++;
			}
			my $tempscr = ord($t[$i])-$scoring;
			if(ord($t[$i])-$scoring < $lowlim) {
				$secondOK = 0;
			}
		}
		if($score_cnt/scalar(@t) >= $minfrac) {
			$secondOK = 1;
		}
		else {
			$secondOK = 0;
		}
		
		#Printing paired end reads
		if($firstOK) {
			if($secondOK) {
				print OUT1 $head1 . $newseq1 ."\n" . $plus1 . $newscore1 . "\n";
				print OUT2 $head2 . $newseq2 ."\n" . $plus2 . $newscore2 . "\n";
			}
			else {
				print OUT3 $head1 . $newseq1 ."\n" . $plus1 . $newscore1 . "\n";
			}
		}
		else {
			if($secondOK) {
				print OUT3 $head2 . $newseq2 ."\n" . $plus2 . $newscore2 . "\n";
			}
		}
	}
	
	#Printing single end reads
	else {
		if($firstOK) {
			print OUT1 $head1 . $newseq1 ."\n" . $plus1 . $newscore1 . "\n";
		}
	}
}


$time = time-$time;
if($time<60) {
	print "Total time elapsed: $time sec.\n";
}
else {
	$time = int($time/60 + 0.5);
	print "Total time elapsed: $time min.\n";
}

# ====================================================
