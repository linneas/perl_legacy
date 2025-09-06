#!/usr/bin/perl

# fastqEndTrimming.pl	       	written by LS, apr 2010
# =====================================================
# Takes a pair of fastq files, and first trim all reads
# by removing non high quality bases in the end. Then 
# it goes through each pair and removes it (from both
# files) if one of the reads has a really low quality
# base, or if not a certain fraction reaches the HQ
# threshold.
# =====================================================
# usage perl


use strict;
#use warnings;

my $time =time;

# Input parameters
my @in = ($ARGV[0],$ARGV[1]);
my $HQlim = $ARGV[2];
my $minfrac = $ARGV[3];
my $lowlim = $ARGV[4];
my $out_prefix = $ARGV[5];

# Other parameters
my $maxNoHQ = 5;
my $maxNoLQ = 1;
my $minReadLen = 50;

# ====================================================

&trimEnds($in[0], $HQlim, $lowlim, $maxNoHQ, $maxNoLQ, $minReadLen, 1);
&trimEnds($in[1], $HQlim, $lowlim, $maxNoHQ, $maxNoLQ, $minReadLen, 2);
&removeBad($in[0], $in[1], $out_prefix, $lowlim, $HQlim, $minfrac);


# ====================================================
sub trimEnds { 

	my $reads = shift;
	my $HQ = shift;
	my $LQ = shift;
	my $maxHQ = shift;
	my $maxLQ = shift;
	my $len = shift;
	my $pairNo = shift;

	my($head, $seq, $plus, $qual);
	my $time = time;

	print "Checking the tips of read " . $pairNo . "\n";

	open(IN, $reads);
	my $out = "temp" . $pairNo . ".fastq";
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

		my @t = split(undef, $qual);
		my @s = split(undef, $seq);

		while(scalar(@t)>$len && $HQ_warn<=$maxHQ) {

			if (ord($t[scalar(@t)-1])-64 < $HQ) {
				
				if ($HQ_warn > 0 && $LQ_flag <= $maxLQ && ord($t[scalar(@t)-1])-64 > $LQ) {
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
	$time = (time-$time)/60;
	print "Done! ($time min)\n";
}

sub removeBad {

	my $read1 = shift;
	my $read2 = shift;
	my $outpref = shift;
	my $lowlim = shift;
	my $HQ = shift;
	my $frac = shift;
		
	my ($head,$seq,$plus,$qual,$head2,$seq2,$plus2,$qual2);
	
	my $out1 = $outpref . "_pair1.fastq";
	my $out2 = $outpref . "_pair2.fastq";
	my $time = time;

	print "Removing low quality reads\n";
	open(TR1, "temp1.fastq");
	open(TR2, "temp2.fastq");
	open(OUT1, ">$out1");
	open(OUT2, ">$out2");
	
	while(<TR1>) {
		
		$head = $_;
		$seq = <TR1>;
		$plus = <TR1>;
		chomp($qual =<TR1>);	
		$head2 = <TR2>;
		$seq2 = <TR2>;
		$plus2 = <TR2>;
		chomp($qual2 =<TR2>);	
		my $LQ_flag = "off";

	
		my @t1 = split(undef, $qual);
		my @t2 = split(undef, $qual2);

		my $score1_cnt=0;
		my $score2_cnt=0;


		for (my $i=0; $i<scalar(@t1); $i++) {
			if(ord($t1[$i])-64 >= $HQ) {
				$score1_cnt++;
			}
			my $tempscr = ord($t1[$i])-64;
			if(ord($t1[$i])-64 < $lowlim) {
				$LQ_flag = "on";
				last;
			}
		}
		# Checks the fraction HQ and low lim LQ is fulfilled for the first read in pair
		# if so, chech the second read
		if($score1_cnt/scalar(@t1) >= $frac && $LQ_flag eq "off") {
			for (my $i=0; $i<scalar(@t2); $i++) {
				if(ord($t2[$i])-64 >= $HQ) {
					$score2_cnt++;
				}
				if(ord($t1[$i])-64 < $lowlim) {
					$LQ_flag = "on";
					last;
				}

			}
			# Checks that the filters are fulfilled for the second read and print
			if($score2_cnt/scalar(@t2) >= $frac && $LQ_flag eq "off") {
				print OUT1 $head . $seq . $plus . $qual . "\n";
				print OUT2 $head2 . $seq2 . $plus2 . $qual2 . "\n";
			}
		}
	}
	system("rm temp1.fastq temp2.fastq");
	$time = (time - $time)/60;
	print "Done! ($time min)\n";
}

