#!/usr/bin/perl


# # # # # # # # #
# extractSplitScaffWithChr.pl
# written by Linnéa Smeds                   2 July 2012
# =====================================================
# 
# =====================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;

# Input parameters
my $SPLITINFO = $ARGV[0];	# SplittingInfo file from assignScaffolds2Chrom output
my $PREFIX = $ARGV[1];
my $SUFFIX = $ARGV[2];
my $OUT = $ARGV[3];

open(OUT, ">$OUT");

# Open file and go through scaffolds
open(IN, $SPLITINFO);
while(<IN>) {
	if (/^S0/) {
		my $scaff = $_;
		chomp($scaff);
		
		my ($topHitName, $topHit, $secBestName, $secBest) = ("",0,"",0);


		my $next = <IN>;
		while ($next =~ m/\tchr/) {
			my @t = split(/\s+/, $next);
			unless($next =~ /chrUn/) {
				if($t[2]>$topHit) {
					$secBestName=$topHitName;
					$secBest=$topHit;
					$topHitName=$t[1];
					$topHit=$t[2];
				}
				else {
					if($t[2]>$secBest) {
						$secBestName=$t[1];
						$secBest=$t[2];
					}
				}
			}			
			if(eof(IN)) {
				last;
			}	
			$next = <IN>;
		}
		seek(IN, -length($next), 1);

		# Now we know which chromosomes the scaffolds are split between
		# Check between which positions the split most likely occurs
		my $temp = "temp_".$scaff;
		my $input = $PREFIX."*".$SUFFIX;
		my $no1 = $topHitName."_";
		my $no2 = $secBestName."_";
		# Make temp file with positions
		system("grep $scaff $input |grep -v chrUn |sort -k6n |egrep -i \"$no1|$no2\"".
			" |awk '{split(\$1,s,\":\");print \"chr\"s[2]\"\\t\"\$6 \"\\t\"\$7}' >$temp");

		#Open temp file
		my %regions;
		my $regcnt = 1;
		my $cnt = 1;
		my ($chr, $start, $stop);
		open(TMP, $temp);
		while(my $line = <TMP>) {
			if($cnt==1) {
				($chr, $start, $stop) = split(/\s+/, $line);
			}
			else {
				my @tab = split(/\s+/, $line);
				if($tab[0] eq $chr || $tab[2]<$stop) {
					$stop = $tab[2];
				}
				else {
					$regions{$regcnt}{'chr'}=$chr;
					$regions{$regcnt}{'start'}=$start;
					$regions{$regcnt}{'stop'}=$stop;
					$regcnt++;
					($chr, $start, $stop) = ($tab[0], $tab[1], $tab[2]);
				}
			}
			$cnt++;
		}
		$regions{$regcnt}{'chr'}=$chr;
		$regions{$regcnt}{'start'}=$start;
		$regions{$regcnt}{'stop'}=$stop;
	
		close(TMP);
	#	system("rm $temp");

		if(scalar(keys %regions) == 2) {
			print "$scaff - only one possible split here!\n";
		}
		else {
			my $noOfSpl = scalar(keys %regions)-1;
			print "$scaff - number of splits: $noOfSpl\n";
		}

		print OUT $scaff."\t".$topHitName."\t".$secBestName."\t";

		my $n=1;
		my $prevstop = "";
		foreach my $key (sort keys %regions) {
			print "\t$key\t".$regions{$key}{'chr'}."\t".
							$regions{$key}{'start'}."\t".
							$regions{$key}{'stop'}."\t"."\n";
			if($n==2) {
				print OUT $prevstop."-".$regions{$key}{'start'};
			}
			elsif($n>2){
				print OUT ";".$prevstop."-".$regions{$key}{'start'};
			}
			$n++;
			$prevstop=$regions{$key}{'stop'};	
		}
		print OUT "\n";
	}
}
close(OUT);
close(IN);
