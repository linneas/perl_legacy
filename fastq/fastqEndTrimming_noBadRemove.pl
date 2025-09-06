#!/usr/bin/perl

# fastqEndTrimming.pl
# September 2010	
# Author: Linnéa Smeds (linnea.smeds@ebc.uu.se)

use strict;
use warnings;
use Getopt::Long;


my $usage = "# fastqEndTrimming.pl
# September 2010	
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

# Input parameters
my ($read1,$read2,$prefix,$HQlim,$lowlim,$minfrac,$minReadLen,$maxNoHQ,$maxNoLQ,$scoring,$help);
GetOptions(
  	"fastq1=s" => \$read1,
   	"fastq2=s" => \$read2,
  	"prefix=s" => \$prefix,
  	"hq=i" => \$HQlim,
	"lq=i" => \$lowlim,
	"frac=i" => \$minfrac,
	"minlen=i" => \$minReadLen,
	"mh=i" => \$maxNoHQ,
   	"ml=i" => \$maxNoLQ,
	"sc=i" => \$scoring,
	"h" => \$help);

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
&trimEnds($read1, $HQlim, $lowlim, $maxNoHQ, $maxNoLQ, $minReadLen, $scoring, 1);

if($read2) {
	unless(-e $read2) {
		die "Error: File $read2 doesn't exist!\n";
	}
	&trimEnds($read2, $HQlim, $lowlim, $maxNoHQ, $maxNoLQ, $minReadLen, $scoring, 2);
#	&removeBadPairs($read1, $read2, $prefix, $lowlim, $HQlim, $minfrac, $scoring);
}
else {
#	&removeBadSingle($read1, $prefix, $lowlim, $HQlim, $minfrac, $scoring);
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
# Subroutines

sub trimEnds { 

	my $reads = shift;
	my $HQ = shift;
	my $LQ = shift;
	my $maxHQ = shift;
	my $maxLQ = shift;
	my $len = shift;
	my $sc = shift;
	my $pairNo = shift;

	my($head, $seq, $plus, $qual);
	my $curr_time = time;

	print "Checking the tips of file " . $pairNo . "...\n";

	open(IN, $reads);
	my $out = $reads."_temp" . $pairNo . ".fastq";
	open(OUT, ">$out");
	

	while(my $line = <IN>) {
		$head = $line;
		chomp($seq = <IN>);
		$plus = <IN>;
		chomp($qual = <IN>);
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
		for(@s) {
			$newseq.=$_;
		}
		for(@t) {
			$newscore.=$_;
		}
		$newscore .=$qual_end;
		$newseq .= $seq_end;
		print OUT $head . $newseq . "\n" . $plus . $newscore . "\n";		
	}	
	close(OUT);
	close(IN);
	$curr_time = time-$curr_time;
	if($curr_time<60) {
		print "\tdone! ($curr_time sec)\n";
	}
	else {
		$curr_time = int($curr_time/60 + 0.5);
		print "\tdone! ($curr_time min)\n";
	}
}

sub removeBadPairs {

	my $read1 = shift;
	my $read2 = shift;
	my $outpref = shift;
	my $lowlim = shift;
	my $HQ = shift;
	my $frac = shift;
	my $sc = shift;
		
	my ($head,$seq,$plus,$qual,$head2,$seq2,$plus2,$qual2);
	
	my $out1 = $outpref . "_trim1.fastq";
	my $out2 = $outpref . "_trim2.fastq";
	my $out3 = $outpref . "_trim_unpaired.fastq";
	my $curr_time = time;

	print "Removing low quality reads...\n";
	open(TR1, "$read1"."_temp1.fastq");
	open(TR2, "$read2"."_temp2.fastq");
	open(OUT1, ">$out1");
	open(OUT2, ">$out2");
	open(OUT3, ">$out3");
	
	my ($OK, $removed, $single) = (0,0,0);

	while(<TR1>) {
		
		$head = $_;
		$seq = <TR1>;
		$plus = <TR1>;
		chomp($qual =<TR1>);	
		$head2 = <TR2>;
		$seq2 = <TR2>;
		$plus2 = <TR2>;
		chomp($qual2 =<TR2>);	
		my $LQ_flag1 = "off";
		my $LQ_flag2 = "off";

	
		my @t1 = split("", $qual);
		my @t2 = split("", $qual2);

		my $score1_cnt=0;
		my $score2_cnt=0;


		for (my $i=0; $i<scalar(@t1)-1; $i++) {
				my $test = ord($t1[$i])- $sc;
			#	print "nu är i $i och test $test\n"; 
			if(ord($t1[$i])-$sc >= $HQ) {
				$score1_cnt++;
			}
			my $tempscr = ord($t1[$i])-$sc;
			if(ord($t1[$i])-$sc < $lowlim) {
				$LQ_flag1 = "on";
				last;
			}
		}
		my $leng=scalar(@t2);
		#print "for this sequence: $qual2 with length $leng\n";
		for (my $i=0; $i<scalar(@t2)-1; $i++) {
				my $test = $t2[$i];
				#print "nu är i $i och t2[$i]=$test\n"; 
			if(ord($t2[$i])-$sc >= $HQ) {
				$score2_cnt++;
			}
			if(ord($t2[$i])-$sc < $lowlim) {
				$LQ_flag2 = "on";
				last;
			}
		}

		# Checks the fraction HQ and low lim LQ is fulfilled for the first read in pair
		# if so, chech the second read
		if($score1_cnt/scalar(@t1) >= $frac && $LQ_flag1 eq "off") {
			
			# Checks that the filters are fulfilled for the second read and print
			if($score2_cnt/scalar(@t2) >= $frac && $LQ_flag2 eq "off") {
				print OUT1 $head . $seq . $plus . $qual . "\n";
				print OUT2 $head2 . $seq2 . $plus2 . $qual2 . "\n";
				$OK+=2;
			}
			else {
				print OUT3 $head . $seq . $plus . $qual . "\n";
				$single++;
				$removed++;
			}
		}
		else {
			if($score2_cnt/scalar(@t2) >= $frac && $LQ_flag2 eq "off") {
				print OUT3 $head2 . $seq2 . $plus2 . $qual2 . "\n";
				$single++;
				$removed++;
			}
			else {
				$removed+=2;
			}
		}
	}
	system("rm $read1"."_temp1.fastq $read2"."_temp2.fastq");
	$curr_time = time-$curr_time;
	if($curr_time<60) {
		print "\tdone! ($curr_time sec)\n";
	}
	else {
		$curr_time = int($curr_time/60 + 0.5);
		print "\tdone! ($curr_time min)\n";
	}
	print "$OK reads in pairs and $single single reads kept, $removed reads removed.\n";
}

sub removeBadSingle {

	my $read1 = shift;
	my $outpref = shift;
	my $lowlim = shift;
	my $HQ = shift;
	my $frac = shift;
	my $sc = shift;
		
	my ($head,$seq,$plus,$qual);
	
	my $out1 = $outpref . "_trim.fastq";
	my $curr_time = time;

	print "Removing low quality reads...\n";
	open(TR1, "$read1"."_temp1.fastq");
	open(OUT1, ">$out1");
	
	my ($OK, $removed, $single) = (0,0,0);

	while(<TR1>) {
		
		$head = $_;
		$seq = <TR1>;
		$plus = <TR1>;
		chomp($qual =<TR1>);	
		my $LQ_flag1 = "off";
	
		my @t1 = split("", $qual);

		my $score1_cnt=0;


		for (my $i=0; $i<scalar(@t1)-1; $i++) {
			if(ord($t1[$i])-$sc >= $HQ) {
				$score1_cnt++;
			}
			my $tempscr = ord($t1[$i])-$sc;
			if(ord($t1[$i])-$sc < $lowlim) {
				$LQ_flag1 = "on";
				last;
			}
		}
	
		# Checks the fraction HQ and low lim LQ is fulfilled for the read
		if($score1_cnt/scalar(@t1) >= $frac && $LQ_flag1 eq "off") {
			print OUT1 $head . $seq . $plus . $qual . "\n";
			$OK+=1;
		}
		else {
			$removed++;
		}
	}
	system("rm $read1"."_temp1.fastq");
	$curr_time = time-$curr_time;
	if($curr_time<60) {
		print "\tdone! ($curr_time sec)\n";
	}
	else {
		$curr_time = int($curr_time/60 + 0.5);
		print "\tdone! ($curr_time min)\n";
	}
	print "$OK reads kept, $removed reads removed.\n";
}


