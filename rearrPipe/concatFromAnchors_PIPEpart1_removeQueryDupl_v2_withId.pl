#!/usr/bin/perl

# # # # # #
# concatFromAnchors_PIPEpart1_removeQueryDupl_v2_withId.pl
# written by Linnéa Smeds       18 April, mod 31 oct 2013,
#
# 4 Mar 2015: Now takes Identity as an extra field in the 
# infile
#
# 31 Oct 2013 bugfixed! Overlap filtering removes bad lines
# from the hash, but in last step the lines were written from
# the original list, with only col1&2 as identifyer (meaning
# that duplicated lines were all printed).
#
# 15 Nov 2012 and 21 Feb 2013, now filters overlap in the
# reference in a more intelligent way, comparing score
# and saving the best.
# ---------------------------------------------------------
# DESCRIPTION:
# Takes a list of reference chromosomes, a lastz file (all
# chromosomes in one file), a config file with parameters
# for the stepwise merging, and a file with the scaffold 
# lengths.

use strict;
use warnings;


# Input parameters
my $chrList = $ARGV[0];
my $lastzfile = $ARGV[1];
my $configFile = $ARGV[2];
my $scaLenFile = $ARGV[3];

my ($steps, $last);
my $concatList = "all_cat.list";
open(OUT, ">$concatList");		#Initiating file
close(OUT);

# GO THROUGH ALL CHROMOSOMES ONE BY ONE
# AND RUN THE DIFFERENT STEPS
open(IN, $chrList);
while(<IN>) {
	my $chrom = $_;
	chomp($chrom);

	&makeAnchorFile($chrom, $lastzfile);
	&removeOverlaps($chrom);
	&removeQueryOverlaps($chrom);
	($last, $steps) = &allMergeSteps($chrom, $configFile);
	&makeScaffoldList($chrom, $last);
	
}
close(IN);

# RUN FINAL STEPS FOR CONCATENATED FILES
#&makeConcatAnchorFile($steps);
#&checkMultAndAssign($steps, $concatList, $scaLenFile, $chrList);

# PREPARE LISTS FOR MAKING THE ARTIFICIAL CHROMOSOMES
#open(IN, $chrList);
#while(<IN>) {
#	my $chrom = $_;
#	chomp($chrom);

#	&makeConcatList($chrom, $steps);
#}
#close(IN);



# Subroutines
# -----------------------------------------

sub makeAnchorFile {

	my $chrom = shift;
	my $file = shift;

	my $chrNo = $chrom;
	$chrNo =~ s/chr//;
	my $outAnc = $chrom.".anchors";
	system("awk '(\$1 ==\"$chrNo\"){print}' $lastzfile | sort -k2n >$outAnc");

}

sub removeOverlaps {

	my $chrom = shift;

#	print "remove overlaps for $chrom\n";

	my $infile = $chrom.".anchors";
	my $outfile = $chrom."_noovl.anchors";

	# Go through anchors and save them in hash
	open(THIS, $infile);
	my %hash = ();
	my @rows = ();
	my $rowcnt = 0;
	while(<THIS>) {
		my @tab = split(/\s+/, $_);
		my $printflag="on";
		if(defined $hash{$tab[0]}{$tab[1]}) {		#If there are anchors EXACTLY overlapping!
			if($tab[8]<$hash{$tab[0]}{$tab[1]}{'score'}) {		#(Otherwise only last is saved)
				$printflag="off";
			}
		}
		if($printflag eq "on") {
			$hash{$tab[0]}{$tab[1]}{'querid'} = $tab[4];
			$hash{$tab[0]}{$tab[1]}{'querstart'} = $tab[5];
			$hash{$tab[0]}{$tab[1]}{'querstop'} = $tab[6];
			$hash{$tab[0]}{$tab[1]}{'querdir'} = $tab[7];
			$hash{$tab[0]}{$tab[1]}{'stop'} = $tab[2];
			$hash{$tab[0]}{$tab[1]}{'dir'} = $tab[3];
			$hash{$tab[0]}{$tab[1]}{'score'} = $tab[8];
			$hash{$tab[0]}{$tab[1]}{'id'} = $tab[9];
			$hash{$tab[0]}{$tab[1]}{'order'} = $rowcnt;
			$rows[$rowcnt] = $_;
			$rowcnt++;
		}
		else {
			print "Row removed because of target complete duplication: $_";
		}
	}
	close(THIS);

	#Go through chromosomes
	foreach my $chr (keys %hash) {
	my $oldstart;
	my $removeFlag = "off";
	my $cnt = 0;
	my $lastline;

		#Go through start positions 
		foreach my $start (sort {$a<=>$b} keys %{$hash{$chr}}) {
			if($cnt>0) {
				#If this segment is overlapping with previous one
				if($hash{$chr}{$oldstart}{'stop'}>=$start) {
			
					my $oldlen = $hash{$chr}{$oldstart}{'stop'}-$oldstart+1;
					my $len = $hash{$chr}{$start}{'stop'}-$start+1;
		 			my $oldscore = $hash{$chr}{$oldstart}{'score'};
		 			my $score = $hash{$chr}{$start}{'score'};
		
	
					if($oldlen>$len && $oldscore>1.5*$score) {
						delete $hash{$chr}{$start};
	#					print "delete this line: $chr $start\n";
						$start = $oldstart;
					}
					elsif($len>$oldlen && $score>1.5*$oldscore) {
						delete $hash{$chr}{$oldstart};
	#					print "delete old line: $chr $oldstart\n";
					}
					else {
						if($score>$oldscore) {
	#						print "delete old line: $chr $oldstart\n";
							delete $hash{$chr}{$oldstart};
						}
						else {
							delete $hash{$chr}{$start};
	#						print "delete this line: $chr $start\n";
							$start = $oldstart;
						}
						$removeFlag="on";
					}
				}
				else {
					if($removeFlag eq "on") {
	#					print "In the else, delete old line: $chr $oldstart\n";
						delete $hash{$chr}{$oldstart};
					}
					$removeFlag="off";
				}
			}
			$oldstart = $start;
			$cnt++;
		}
		if($removeFlag eq "on") {
			delete $hash{$chr}{$oldstart};
		}
	}

	
	#Go through the hash again and print in in original order
	open(OUT, ">$outfile");
	foreach my $line (@rows) {
		my @tabs = split(/\s+/, $line);
		if(defined $hash{$tabs[0]}{$tabs[1]}) {
			print OUT $tabs[0]."\t".$tabs[1]."\t".$hash{$tabs[0]}{$tabs[1]}{'stop'}."\t".$hash{$tabs[0]}{$tabs[1]}{'dir'}.
			"\t".$hash{$tabs[0]}{$tabs[1]}{'querid'}."\t".$hash{$tabs[0]}{$tabs[1]}{'querstart'}."\t".$hash{$tabs[0]}{$tabs[1]}{'querstop'}."\t".
			"\t".$hash{$tabs[0]}{$tabs[1]}{'querdir'}."\t".$hash{$tabs[0]}{$tabs[1]}{'score'}."\t".$hash{$tabs[0]}{$tabs[1]}{'id'}."\n";
			delete $hash{$tabs[0]}{$tabs[1]};
		}
	}
	close(OUT);
}

sub removeQueryOverlaps {
	my $chrom = shift;

	my $infile = $chrom."_noovl.anchors";
	my $outfile = $chrom.".cleaned.anchors";

	open(THIS, $infile);
	my %hash = ();
	my @rows = ();
	my $rowcnt = 0;
	while(<THIS>) {
		my @tab = split(/\s+/, $_);
		my $printflag="on";
		if(defined $hash{$tab[4]}{$tab[5]}) {		#If there are anchors EXACTLY overlapping!
			if($tab[8]<$hash{$tab[4]}{$tab[5]}{'score'}) {		#(Otherwise only last is saved)
				$printflag="off";
			}
		}
		if($printflag eq "on") {
			$hash{$tab[4]}{$tab[5]}{'refid'} = $tab[0];
			$hash{$tab[4]}{$tab[5]}{'refstart'} = $tab[1];
			$hash{$tab[4]}{$tab[5]}{'refstop'} = $tab[2];
			$hash{$tab[4]}{$tab[5]}{'refdir'} = $tab[3];
			$hash{$tab[4]}{$tab[5]}{'stop'} = $tab[6];
			$hash{$tab[4]}{$tab[5]}{'dir'} = $tab[7];
			$hash{$tab[4]}{$tab[5]}{'score'} = $tab[8];
			$hash{$tab[4]}{$tab[5]}{'id'} = $tab[9];
			$rows[$rowcnt] = $_;
			$rowcnt++;
		}
		else {
			print "Row removed because of query complete duplication: $_";
		}
	}
	close(THIS);

	#Go through scaffolds
	foreach my $scaf (keys %hash) {
		my $oldstart;
		my $removeFlag = "off";
		my $cnt = 0;
		my $lastline;

		#Go through start positions 
		foreach my $start (sort {$a<=>$b} keys %{$hash{$scaf}}) {
			if($cnt>0) {
				#If this segment is overlapping with previous one
				if($hash{$scaf}{$oldstart}{'stop'}>=$start) {
				
					my $oldlen = $hash{$scaf}{$oldstart}{'stop'}-$oldstart+1;
					my $len = $hash{$scaf}{$start}{'stop'}-$start+1;
		 			my $oldscore = $hash{$scaf}{$oldstart}{'score'};
		 			my $score = $hash{$scaf}{$start}{'score'};
			
		
					if($oldlen>$len && $oldscore>1.5*$score) {
						delete $hash{$scaf}{$start};
						$start = $oldstart;
					}
					elsif($len>$oldlen && $score>1.5*$oldscore) {
						delete $hash{$scaf}{$oldstart};
					}
					else {
						if($score>$oldscore) {
							delete $hash{$scaf}{$oldstart};
						}
						else {
							delete $hash{$scaf}{$start};
							$start = $oldstart;
						}
						$removeFlag="on";
					}
				}
				else {
					if($removeFlag eq "on") {
						delete $hash{$scaf}{$oldstart};
					}
					$removeFlag="off";
				}
			}
			$oldstart = $start;
			$cnt++;
		}
		if($removeFlag eq "on") {
			delete $hash{$scaf}{$oldstart};
		}
	}

	
	#Go through the hash again and print in in original order
	open(OUT, ">$outfile");
	foreach my $line (@rows) {
		my @tabs = split(/\s+/, $line);
		if(defined $hash{$tabs[4]}{$tabs[5]}) {
			print OUT $hash{$tabs[4]}{$tabs[5]}{'refid'}."\t".$hash{$tabs[4]}{$tabs[5]}{'refstart'}."\t".$hash{$tabs[4]}{$tabs[5]}{'refstop'}."\t".
			$hash{$tabs[4]}{$tabs[5]}{'refdir'}."\t".$tabs[4]."\t".$tabs[5]."\t".$hash{$tabs[4]}{$tabs[5]}{'stop'}."\t".
			$hash{$tabs[4]}{$tabs[5]}{'dir'}."\t".$hash{$tabs[4]}{$tabs[5]}{'score'}."\t".$hash{$tabs[4]}{$tabs[5]}{'id'}."\n";
			delete $hash{$tabs[4]}{$tabs[5]};
		}
	}
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
						# merge identity:
					    my ($on, $od)=split(/\//,$oldinfo[9]);
						my ($nn, $nd)=split(/\//,$info[9]);
						$info[9] = join("/", $on+$nn, $od+$nd); 
					}
					elsif(($info[7] eq "-") && (abs($info[6]-$oldinfo[5]) < $threshold) && ($info[5]<$oldinfo[5])) {
						$info[1] = $oldinfo[1];
						$info[6] = $oldinfo[6];
						# merge identity:
			    	    my ($on, $od)=split(/\//,$oldinfo[9]);
				    	my ($nn, $nd)=split(/\//,$info[9]);
				    	$info[9] = join("/", $on+$nn, $od+$nd);

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
	
	my $prevFile = $chrom.".cleaned.anchors";
	my $outStep = "";
	while(my $line = <CNF>) {
		chomp($line);
		if($line =~ m/^#/ || $line eq "") {
			next;
		}
		else {
			my ($type, $lim) = split(/\s+/, $line);
			$outStep = $chrom."_step".$cnt.".anchors";
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

sub makeScaffoldList {

	my $chrom = shift;
	my $outStep = shift;
	my $outCatList = $chrom."_cat.list";
	system("awk '{print \$5\"\\t\"\$8}' $outStep >$outCatList");
	system("awk '{print \"$chrom\t\"\$5\"\\t\"\$8}' $outStep >>$concatList");

}

sub makeConcatAnchorFile {
	my $steps = shift;

	my $concatAnch = "all_step$steps.anchors";
	system("cat chr*_step$steps.anchors >$concatAnch");
}


sub checkMultAndAssign {

	my $steps = shift;
	my $concatList = shift;
	my $scaLenFile = shift;
	my $chrList = shift;

	print "step is $steps\n";

	my $concatAnch = "all_step$steps.anchors";
	
	system("awk '{print \$1\"\t\"\$5}' $concatAnch |sort |uniq -c |awk '{print \$3}' |sort |uniq -c |awk '(\$1>1){print \$2}' >anchor_to_multiple");
	system("perl ~/private/scripts/rearrPipe/assignScaffolds2Chrom.pl anchor_to_multiple $concatList $scaLenFile step$steps.anchors $chrList anchor_to_multiple_nonUn");

}

sub makeConcatList {

	my $chrom = shift;
	my $step = shift;

	my $oldlist = $chrom."_step$step.anchors.cleaned";
	my $newlist = $chrom."_artificial.list";

	system("awk '{len=\$7-\$6; print \$5\"\t\"len\"\t\"\$8}' $oldlist >makeList.tempfile");

	open(LST, "makeList.tempfile");
	my %seqs = ();
	my $cnt=1;
	while(<LST>) {
		my ($scaff, $len, $sign) = split(/\s+/,$_);
		unless ($scaff eq "") {

			my $next = <IN>;
			my ($nextscaff,$nextlen,$nextsign) = split(/\s+/,$next);
			while ($nextscaff eq $scaff && $nextsign eq $sign) {
				
				$len+=$nextlen;
				if(eof(IN)) {
					last;
				}	
				$next = <IN>;
				($nextscaff,$nextlen,$nextsign) = split(/\s+/,$next);
			}
			seek(IN, -length($next), 1);


			if(defined $seqs{$scaff}) {
				if($len > $seqs{$scaff}{'len'}) {
					$seqs{$scaff}{'sign'} = $sign;
					$seqs{$scaff}{'len'} = $len;
					$seqs{$scaff}{'order'} = $cnt;
				}
			}
			else {
				$seqs{$scaff}{'sign'} = $sign;
				$seqs{$scaff}{'len'} = $len;
				$seqs{$scaff}{'order'} = $cnt;
			}
			$cnt++;	
		}
	}
	close(LST);
	system("rm makeList.tempfile");

	unless (!keys %seqs) {
		open(OUT, ">$newlist");
		foreach my $key (sort {$seqs{$a}{'order'} <=> $seqs{$b}{'order'}} keys %seqs) {
			print OUT $key."\t".$seqs{$key}{'sign'}."\n";
		}
		close(OUT);
	}
}
