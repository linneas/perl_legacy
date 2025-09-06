#!/usr/bin/perl


# # # # # #
# getScaffoldListFromLinkageMap.pl
# written by Linnéa Smeds                  15 Sept 2011
# =======================================================
# Takes a linkage map file with 4 columns (linkage group,
# marker, genetic position and scaffold name) and also a
# list with all markers, scaffolds and positions on the 
# scaffolds (in Mb scale). 
# Prints a new list with the scaffolds in the (most) 
# right order together with direction (and a comment if 
# the strand is unknown). 
# =======================================================
# Bugfixed 28 Sept 2011, there was a problem when having 
# the same scaffold linking to more than one location, if
# each location only had one marker.
# NB! Still a problem when there are scaffold linking to 
# more than one location, resulting in two loss of sign
# on chrom Z. Need to be fixed! (comm. added 3 okt 2011)

use strict;
use warnings;

#Input parameters
my $linkList = $ARGV[0];	#Four columns
my $posList = $ARGV[1];		#Three columns
my $LinkageGroup = $ARGV[2];
my $out = $ARGV[3];

#Save all positions
my %position = ();
open(POS, $posList);
while(<POS>) {
	my ($marker, $scaff, $pos) = split(/\s+/, $_);
	$position{$marker} = $pos;
}
close(POS);

#Go through the list
open(IN, $linkList);
my %scaffList = ();
my %scaffs = ();
my $cnt = 0;
my ($prevScaf,$prevPos,$prevStrand, $prevStrandSupport, $otherStrandSupport, $no) = ("","","",0,0,0);
my ($otherStransSuggest,) = ("", 0);
my ($group, $marker, $genetDist, $scaff, $pos, $strand);
while(<IN>) {
	($group, $marker, $genetDist, $scaff) = split(/\s+/, $_);
	$pos = $position{$marker};
	$strand = "";

	#We only want to extract a specific linkage group
	if ($group eq $LinkageGroup && $scaff ne "-") {
#		print "Looking at linkage $group, scaffold $scaff\n";
		print "the position for $marker is $pos\n";
		if($cnt == 0) {
			$prevScaf = $scaff;
			$prevPos = $pos;
			$no++;
		}
		else {
			#if we find several lines of the same scaffold, all info is cumulatively added
			print "looking at $scaff while prevscaff id $prevScaf\n";
			if($scaff eq $prevScaf) {
	
				if($pos>=$prevPos) {
					print "$scaff: positive direction\n";
					$strand="+";
				}
				else {
					print "$scaff: negative direction\n";
					$strand="-";
				}
				#If the new marker suggest that the scaffold should be reversed
				if($prevStrand ne "" && $strand ne $prevStrand) {
					print "Conflict in $scaff! previous direction was $prevStrand but $marker suggest $strand!\n";
					$otherStrandSupport++;
				}
				else {
					$prevStrandSupport++;
					$prevStrand = $strand;
				}
				$prevPos=$pos;
				$no++;
			}
			#When we find a new scaffold, all saved stuff is moved to the hash
			else {
#				print "printing info about $prevScaf\n";
				if (!defined $scaffs{$prevScaf}) {
#					print "there where nothing saved for $scaff\n";
					$scaffs{$prevScaf}{'order'}=$cnt;
					$scaffs{$prevScaf}{'no'}=$no;
					$scaffs{$prevScaf}{'totno'}=$no;
					$scaffs{$prevScaf}{'direction'}=$prevStrand;
					$scaffs{$prevScaf}{'dirsupport'}=$prevStrandSupport;
					$scaffs{$prevScaf}{'dirconflict'}=$otherStrandSupport;
					$scaffs{$prevScaf}{'lastpos'}=$prevPos;
				}
				#if the same scaffold already is in the hash, the position with the
				# most number of markers is used.
				else {
					if($scaffs{$prevScaf}{'no'}>=$no) {
#						print "$scaff is already found in the hash, with the same number of markers or more\n";
						if($scaffs{$prevScaf}{'direction'} ne "") {
								if($prevStrand eq $scaffs{$prevScaf}{'direction'}) {
									$scaffs{$prevScaf}{'dirsupport'}+=$prevStrandSupport;
									$scaffs{$prevScaf}{'dirconflict'}+=$otherStrandSupport;
								}
								else {
									$scaffs{$prevScaf}{'dirsupport'}+=$otherStrandSupport;
									$scaffs{$prevScaf}{'dirconflict'}+=$prevStrandSupport;
								}
						}
						else {
							print "prevpos has pos $prevPos, and saved in the hash was lastpos ".$scaffs{$prevScaf}{'lastpos'}."\n";
							if($prevPos>=$scaffs{$prevScaf}{'lastpos'}) {
									print "$prevScaf: positive direction\n";
									$scaffs{$prevScaf}{'direction'}="+";
							}
							else {
								print "$prevScaf: negative direction\n";
								$scaffs{$prevScaf}{'direction'}="-";
							}
						}
						$scaffs{$prevScaf}{'lastpos'}=$prevPos;
					}
					$scaffs{$prevScaf}{'totno'}+=$no;
				}
				print "saving $scaff as prevScaf\n";
				$prevScaf = $scaff;
				$prevPos = $pos;
				$no=1;
				$prevStrand=$strand;
				$prevStrandSupport=0;
				$otherStrandSupport=0;
			}
		}
		$cnt++;
	}
}
close(IN);
# saving the last line to the hash
# print "printing info about $prevScaf\n";
if (!defined $scaffs{$prevScaf}) {
#	print "there where nothing saved for $prevScaf\n";
	$scaffs{$prevScaf}{'order'}=$cnt;
	$scaffs{$prevScaf}{'no'}=$no;
	$scaffs{$prevScaf}{'totno'}=$no;
	$scaffs{$prevScaf}{'direction'}=$prevStrand;
	$scaffs{$prevScaf}{'dirsupport'}=$prevStrandSupport;
	$scaffs{$prevScaf}{'dirconflict'}=$otherStrandSupport;
	$scaffs{$prevScaf}{'lastpos'}=$prevPos;
}
else {
	if($scaffs{$prevScaf}{'no'}>=$no) {
		print "$prevScaf is already found in the hash, with the same number of markers or more\n";
#		$scaffs{$prevScaf}{'lastpos'}=$prevPos;
		if($scaffs{$prevScaf}{'direction'} ne "") {
			if($prevStrand eq $scaffs{$prevScaf}{'direction'}) {
				$scaffs{$prevScaf}{'dirsupport'}+=$prevStrandSupport;
				$scaffs{$prevScaf}{'dirconflict'}+=$otherStrandSupport;
			}
			else {
				$scaffs{$prevScaf}{'dirsupport'}+=$otherStrandSupport;
				$scaffs{$prevScaf}{'dirconflict'}+=$prevStrandSupport;
			}
		}
		else {
			print "prevpos has pos $prevPos, and saved in the hash was lastpos ".$scaffs{$prevScaf}{'lastpos'}."\n";
			if($prevPos>=$scaffs{$prevScaf}{'lastpos'}) {
					print "$prevScaf: positive direction\n";
					$scaffs{$prevScaf}{'direction'}="+";
				}
				else {
					print "$prevScaf: negative direction\n";
					$scaffs{$prevScaf}{'direction'}="-";
				}
		}
	}
	else {
		$scaffs{$prevScaf}{'order'}=$cnt;
		$scaffs{$prevScaf}{'no'}=$no;
		$scaffs{$prevScaf}{'lastpos'}=$prevPos;
		if($prevStrand eq $scaffs{$prevScaf}{'direction'}) {
			$scaffs{$prevScaf}{'dirsupport'}+=$prevStrandSupport;
			$scaffs{$prevScaf}{'dirconflict'}+=$otherStrandSupport;
		}
		else {
			$scaffs{$prevScaf}{'direction'}=$prevStrand;
			my $temp = $scaffs{$prevScaf}{'dirsupport'}+$otherStrandSupport;
			$scaffs{$prevScaf}{'dirsupport'}=$scaffs{$prevScaf}{'dirconflict'}+$prevStrandSupport;
			$scaffs{$prevScaf}{'dirconflict'}=$temp;
		}
	}
	$scaffs{$prevScaf}{'totno'}+=$no;
}


open(OUT, ">$out");
				
# Printing the results
foreach my $key (sort {$scaffs{$a}{'order'} <=> $scaffs{$b}{'order'}} keys %scaffs) {
#	print "printing info of $key, the saved direction is ".$scaffs{$key}{'direction'}."\n"; 
	if($scaffs{$key}{'totno'}==1) {
		print OUT $key."\t+\t(un)\n";
	}
	else {
		my $dir = "";
		if($scaffs{$key}{'dirsupport'}>=$scaffs{$key}{'dirconflict'}) {
			$dir=$scaffs{$key}{'direction'};
		}
		else {
			if($scaffs{$key}{'direction'} eq "+") {
				$dir="-";
			}
			else {
				$dir="+";
			}
		}
		print OUT $key."\t".$dir."\tok\n";
	}
}
close(OUT);

