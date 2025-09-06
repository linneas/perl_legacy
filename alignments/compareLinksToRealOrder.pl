#!/usr/bin/perl

# checkAllEndsForLinks.pl
# written by Linnéa Smeds                       15 May 2012
# =========================================================
# Take the output from "checkAllEndsForLinks" and check for
# each adjacent pair on the "scaffold on chrom" list if 
# they seem to be adjacent in reality as well.
# =========================================================


use strict;
use warnings;
#use List::Util qw[min max];


# Input parameters
my $linkFile = $ARGV[0];
my $scaffoldList = $ARGV[1];
my $outpref = $ARGV[2];
#my $LengthFile = $ARGV[2];
#my $limit = $ARGV[3];


# Save all scaffolds that are listed on the chromosome list
my %knownScaffs = ();
open(IN, $scaffoldList);
while (<IN>) {
	my @tab = split(/\s+/, $_);
	$knownScaffs{$tab[1]}=$tab[0];
}
close(IN);

# Save all links in a hash
my %links = ();		
open(IN, $linkFile);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	my ($startNo, $startDir) = split(/[()]/, $tab[1]);
	my ($endNo, $endDir) = split(/[()]/, $tab[2]);
	my ($startSignif, $endSignif) = ("no", "no");
	if($startNo =~ /\*/) {
		$startSignif = "yes";
		$startNo =~ s/\*//;
	}
	if($endNo =~ /\*/) {
		$endSignif = "yes";
		$endNo =~ s/\*//;
	}

	$links{$tab[0]}{'+'}{'name'}=$startNo;
	$links{$tab[0]}{'+'}{'dir'}=$startDir;
	$links{$tab[0]}{'+'}{'signif'}=$startSignif;
	$links{$tab[0]}{'-'}{'name'}=$endNo;
	$links{$tab[0]}{'-'}{'dir'}=$endDir;
	$links{$tab[0]}{'-'}{'signif'}=$endSignif;
	#	print "Have saved ".$tab[0]." with $startNo, $startDir, $startSignif\n";
}
close(IN);

#Make output files and open
my $outList = $outpref . "_chrom.list";
open(OUT, ">$outList");
my $goodList = $outpref . "_good.links";
open(GOOD, ">$goodList");
my $badList = $outpref . "_bad.links";
open(BAD, ">$badList");

open(IN, $scaffoldList);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	
	my ($chrom, $chr) = ($tab[0], $tab[0]);
	my $scaff = $tab[1];
	my $dir = $tab[3];
	my $oppDir = "";
		
	if($dir eq '+'){
		$oppDir="-";
	}
	if($dir eq '-') {
		$oppDir="+";
	}	

	print "Looking at $chr\n";
	print OUT "$chr\n===============\n";

	my $tempOrder = $scaff."(".$dir.")";



	if(eof(IN)) {
		print "GAME OVER\n";
		print OUT $tempOrder."\n";
	}
	else {
		my $next = <IN>;
		my @nexttab = split(/\s+/, $next);
		my $prev = "WEIRD";

		

		while($chr eq $chrom) {

			my $printFlag = "on";

			#Check links on left side of scaffold
			print "going into left side and checks $scaff and $dir\n";
			my ($check, $nextScaf, $nextDir) = &checkLinks($scaff, $dir);
			print  "output was $check, $nextScaf, $nextDir\n";
			my $lastScaf = $scaff;
			while($check eq "ok") {
				if($tempOrder =~ m/$nextScaf/) {
					print "Have already been here. nextscaf is $nextScaf. Go right instead\n";
					last;
				}
				if(defined $knownScaffs{$nextScaf}) {
					print "Link to $nextScaf is not valid since it occurs somewhere else (".
							$knownScaffs{$nextScaf}.")\n";
					if(defined $knownScaffs{$lastScaf} && $knownScaffs{$nextScaf}) {
						print BAD $lastScaf."\t".$knownScaffs{$lastScaf}."\t".
								$nextScaf."\t".$knownScaffs{$nextScaf}."\n";
					}	
					last;
				}
				$tempOrder = $nextScaf."(".$nextDir.")"."\n".$tempOrder;
				print "Temporder is now : $tempOrder\n";
				print "check is $check, looking at next $nextScaf\n";
				$lastScaf=$nextScaf;
				($check, $nextScaf, $nextDir) = &checkLinks($nextScaf, $nextDir);
			}


			#Check links on right side of scaffold
			($check, $nextScaf, $nextDir) = &checkLinks($scaff, $oppDir);
			$lastScaf = $scaff;
			while($check eq "ok") {
				if($nextScaf eq $nexttab[1]) {
					print "Found a link to the next scaffold on list!\n";
					$tempOrder = $tempOrder."\n".$nextScaf."(".$nextDir.")";
					print "Temporder is now : $tempOrder\n";
					print GOOD $chr."\t".$lastScaf."\t".$nextScaf."\n";
					$printFlag = "off";
					last;
				}
				if(defined $knownScaffs{$nextScaf}) {
					print "Link to $nextScaf is not valid since it occurs somewhere else (".
						$knownScaffs{$nextScaf}.")\n";				
					if(defined $knownScaffs{$lastScaf} && $knownScaffs{$nextScaf}) {
						print BAD $lastScaf."\t".$knownScaffs{$lastScaf}."\t".
								$nextScaf."\t".$knownScaffs{$nextScaf}."\n";
					}	
					last;
				}
	
				$tempOrder = $tempOrder."\n".$nextScaf."(".$nextDir.")";
				print "Temporder is now : $tempOrder\n";
				print "check is $check, looking at next $nextScaf\n";
				$lastScaf=$nextScaf;
				($check, $nextScaf, $nextDir) = &checkLinks($nextScaf, $nextDir);
				$printFlag = "on";
				
			}	

			$prev = $scaff;
			$scaff = $nexttab[1];
			$dir = $nexttab[3];
			$chr = $nexttab[0];
			if($dir eq '+'){
				$oppDir="-";
			}
			if($dir eq '-') {
				$oppDir="+";
			}
			unless($chr ne $chrom) {	
				if(eof(IN)) {
					print OUT $tempOrder."\n";
					last;
				}
				$next = <IN>;
				@nexttab = split(/\s+/, $next);
				if($nextScaf eq "") {
					$nextScaf = $nexttab[1];
					$nextDir = $nexttab[3];
				}
			}
			print "Next time we look at $scaff!\n";
			if($printFlag eq "on") {
				print OUT $tempOrder."\n\n";
				$tempOrder = $scaff."(".$dir.")";
			}
		}
		print "outside of while\n";
	#	unless(eof(IN)) {
		print	"put back line $next";
			seek(IN, -length($next), 1);
	#	}
	}
}
close(IN);
close(OUT);



sub checkLinks {

	my $scaff = shift;
	my $dir = shift;

#	print "inside the sub, looking at $scaff and $dir\n";

	my $key = "";

	if($dir eq "+") {
		$key='+';
	}
	elsif($dir eq "-") {
		$key='-';
	}

	my ($return1, $return2, $return3)=("","","");
	
	if(defined $links{$scaff}) {
		my $next = $links{$scaff}{$key}{'name'};
		my $nextDir = $links{$scaff}{$key}{'dir'};
		my ($nextKey, $oppDir) = ("", "");
		if($nextDir eq "+") {
			$nextKey = '+';
			$oppDir = '-';
		}
		elsif($nextDir eq "-") {
			$nextKey = '-';
			$oppDir = '+'
		}		

		if(defined $links{$next}) {
			if($links{$next}{$nextKey}{'name'} eq $scaff) {
				print "$scaff $key is attached to $next $nextKey - links from both sides\n";
				($return1, $return2, $return3) = ("ok", $next, $oppDir);
		#		print "looking at next in line\n";
		#		my $test= &checkLinks($next, $oppKey);
		#		print "return from sub in sub; $test\n";	
			}
			else {
				print "$scaff $key is attached to $next $nextKey - links from this side only\n";
			}
		}
		else {
			"$scaff doesn't have a link at $dir!\n";
		}
	}
	else {
		print "$scaff is not included in the link list!\n";
	}
	
	return ($return1,$return2,$return3);
}	


