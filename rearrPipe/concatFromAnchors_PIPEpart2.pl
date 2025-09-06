#!/usr/bin/perl

# # # # # #
# concatFromAnchors_PIPEpart2.pl		
# written by Linnéa Smeds        18 April, mod 12 Sept 2011
# ---------------------------------------------------------
# DESCRIPTION:
# Takes a list of chromosomes, and a prefix and suffix for
# the lastz files (one for each chromosome).

use strict;
use warnings;


# Input parameters
my $chrList = $ARGV[0];
my $lastzfile = $ARGV[1];
my $configFile = $ARGV[2];

my ($steps, $last);

# GO THROUGH ALL CHROMOSOMES ONE BY ONE
# AND RUN THE DIFFERENT STEP
open(IN, $chrList);
while(<IN>) {

	my $chrom = $_;
	chomp($chrom);

	&makeAnchorFile($chrom, $lastzfile);
	&removeOverlaps($chrom);
	($last, $steps) = &allMergeSteps($chrom, $configFile);
	&makeSegmentFile($chrom, $last);
	
}
close(IN);

sub makeAnchorFile {

	my $chrom = shift;
	my $file = shift;

	my $chrNo = $chrom;
	$chrNo =~ s/chr//;
	my $outAnc = "cat".$chrom.".anchors";
	system("awk '(\$1 ==\"$chrNo\"){print}' $lastzfile | sort -k2n >$outAnc");

}

sub removeOverlaps {

	my $chrom = shift;

#	print "remove overlaps for $chrom\n";

	my $infile = "cat".$chrom.".anchors";
	my $outfile = "cat".$chrom."_noovl.anchors";

	# Variables
	my @oldinfo;
	my ($oldinfoFlag, $infoFlag) = ("off", "off");
	my @info;
	my $cnt = 0;
	my $lastline;
	open(OUT, ">$outfile");

	# Goes through the (sorted) anchor file and check any consecutive anchors
	# overlaps in the reference genome
	open(THIS,$infile);
	while (my $line = <THIS>) {
		@info = split(/\t/, $line);
		chomp(@info);
		if($cnt>0){	
			if ($info[0] eq $oldinfo[0] && $info[1]<$oldinfo[2]) {
				$infoFlag = "on";
			}
			else {
				if($oldinfoFlag eq "off") {
			    foreach my $val (@oldinfo) {
						print OUT $val."\t";
					}
					print OUT "\n";
				}
			$infoFlag = "off";
			}
		}
		@oldinfo = @info;
		$oldinfoFlag = $infoFlag;
		$cnt++;
	}
	#Prints the last segment
	if($oldinfoFlag eq "off") {
		foreach my $val (@oldinfo)  {
			print OUT $val."\t";
		}
	}
	print OUT "\n";
	close(THIS);
	close(OUT);

}

sub removeShortAnchors {
	my $infile = shift;
	my $outfile = shift;
	my $threshold = shift;

	open(THIS,$infile);
	open(OUT,">$outfile");
	while (my $line = <THIS>) {
		chomp($line);
		unless($line eq "") {
			my @tab = split(/\s/, $line);
			if($tab[2]-$tab[1] >= $threshold && abs($tab[6]-$tab[5])>= $threshold) {
				print OUT $line."\n";		
			}
		}
	}
	close(OUT);
	close(THIS);

}

sub mergeCloseAnchors {
	my $infile = shift;
	my $outfile = shift;
	my $threshold = shift;

	# Variables
	my @oldinfo;
	my @info;
	my $cnt = 0;
	my $lastline;

	# Goes through the anchor file and check if the rows 
	# fulfills the merging conditions
	open(THIS,$infile);
	open(OUT, ">$outfile");
	while (my $line = <THIS>) {
		@info = split(/\s+/, $line);
		chomp(@info);
		if($cnt>0){
			if (defined $info[4] && defined $oldinfo[4] && defined $info[7] && defined $oldinfo[7]) {

				if($info[4] eq $oldinfo[4] && $info[7] eq $oldinfo[7] && ($info[1]-$oldinfo[2] < $threshold)) {
					if(($info[7] eq "+") && (abs($info[5]-$oldinfo[6]) < $threshold) && ($info[6]>$oldinfo[6])){
						$info[1] = $oldinfo[1];
						$info[5] = $oldinfo[5];
					}
					elsif(($info[7] eq "-") && (abs($info[6]-$oldinfo[5]) < $threshold) && ($info[5]<$oldinfo[5])) {
						$info[1] = $oldinfo[1];
						$info[6] = $oldinfo[6];
					}
					else {
						foreach my $val (@oldinfo) {
							print OUT $val."\t";
						}
						print OUT "\n";
					}
				}
				else {
					foreach my $val (@oldinfo) {
						print OUT $val."\t";
					}
					print OUT "\n";
				}
			}
			else {
				print "What happened here? A value is missing on line: $line";
			}
		}
		@oldinfo = @info;
		$cnt++;
	}
	close(THIS);

	#Prints the last segment
	foreach my $val (@oldinfo)  {
		print OUT $val."\t";
	}
	print OUT "\n";
	close(OUT);
}


sub allMergeSteps {

	my $chrom = shift;
	my $configFile = shift;

	open(CNF, $configFile);
	my $cnt = 1;
	
	my $prevFile = "cat".$chrom."_noovl.anchors";
	my $outStep = "";
	while(my $line = <CNF>) {
		chomp($line);
		if($line =~ m/^#/ || $line eq "") {
			next;
		}
		else {
			my ($type, $lim) = split(/\s+/, $line);
			$outStep = "cat".$chrom."_step".$cnt.".anchors";
			if($type eq "M") {
#				print "sending type $type and lim $lim to merge\n";
				&mergeCloseAnchors($prevFile, $outStep, $lim);
			}
			elsif($type eq "R") {
#				print "sending type $type and lim $lim to remove\n";
				&removeShortAnchors($prevFile, $outStep, $lim);
			}
			else {
				die "Type must be either M or R!!";
			}
			$prevFile = $outStep;
			$steps = $cnt;
			$cnt++;
		}
	}
	return ($outStep, $steps);
}

sub makeSegmentFile {
	my $chrom = shift;
	my $outStep = shift;
	
	my $segmentFile = "cat".$chrom.".segments";
	system("awk '(\$5==\"$chrom\"){if(\$8==\"-\"){print \$2\"\t\"\$3\"\t\"\$7\"\t\"\$6}else{print \$2\"\t\"\$3\"\t\"\$6\"\t\"\$7}}' $outStep >$segmentFile");
}
