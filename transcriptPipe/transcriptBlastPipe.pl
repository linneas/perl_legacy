#!/usr/bin/perl

# # # # # #
# transcriptBlastPipe.pl
# written by Linnéa Smeds june 2010, modified aug, oct 2010
# ==========================================================
# Description:
# Blasts a file with assembled contigs or scaffolds against
# a set of reference genes (with or without UTRs). 
# Both query and target file must be in fasta-format, and
# the target file should have a header starting with gene no
# and transcript no separated with "|":
# 	>ENSTGUG00000000001|ENSTGUT00000000001|...
# (The target file cannot contain overlapping reads. By 
# first running the script CheckOverlaps.pl, such genes
# can be removed).
# The current directory should contain a sub folder for the 
# query species (with its fasta file), and the target file
# should be placed in another folder called "data". The 
# script can be placed in the current directory, or anywhere
# (but then the path must be given in the command).
# ==========================================================
# Input files: 
# fastafile - with the sequences for the query species
# speciesDir - the sub dir where the fasta file is located
# overlap - overlap for "merging" two contigs, usually k-mer size
# parallel - (optional) "-a" and the no of processors if the 
# 		blast is to be run in parallel. Eg "-a8".
# ==========================================================
# Usage: 
# perl scripts/transcriptBlastPipe.pl fastafile speciesDir overlap
# 		parallel
# ==========================================================

use strict;
use warnings;

my $time = time;

#Parameters
my $queryFile = $ARGV[0];
my $querySpecies = $ARGV[1];	
my $targetFile = "ens62_gg_300_cds_1000_noOverlaps.fa";
my $speciesTarget = "gg";
my $BlastEval = "1e-10";
my $hitDiff = "1e-10";
my $parallel = $ARGV[3]; #"-a8"; #If running in parallel is not desired, give as "" 
my $Kmer = $ARGV[2];

unless(defined $queryFile && defined $querySpecies && defined $Kmer) {
	&usage();
}

$querySpecies =~ s/\///; #If the name of the dir is given with a "/"

# Directories
my $resDir = "$querySpecies/results/";
my $dataDir = "$querySpecies/data/";
my $dbDir = "$querySpecies/db/";
my $finalDir = "$querySpecies/final/";
my $tmpDir = "$querySpecies/tmp/";

# Files
my $querySeq = $queryFile; #"$querySpecies/$queryFile";
$queryFile =$querySpecies.".fa";
my $targetSeq = "data/$targetFile";
my $formatedQuery = "$dataDir/$queryFile.Reformated.fa";
my $mappingQuery = "$dataDir/$queryFile.Mapping.txt";
my $formatedTar = "$dataDir/$targetFile.Reformated.fa";
my $BlastOut = "$resDir/".$querySpecies."2".$speciesTarget."_blastn.txt";
my $NoHitsOut = "$resDir/".$querySpecies."2".$speciesTarget."_seqWithoutHits.fa";
my $HitSeqOut = "$tmpDir/seqWithHits.fa";
my $HitGenes = "$dataDir/$targetFile"."2".$speciesTarget."_Hit.fa";
my $RecipBlastOut="$resDir/".$querySpecies."2".$speciesTarget."_reciprocalBlastn.txt";
my $tmpHitList = "$tmpDir/hitList.txt";
my $tmpRecHitList = "$tmpDir/ReciprocalHitList.txt";
my $FullOutput = "$resDir/".$querySpecies."2".$speciesTarget."_allHits.fa";
my $FullMapTable = "$resDir/".$querySpecies."2".$speciesTarget."_mapPos.txt";
my $mergedOut = "$tmpDir/".$querySpecies."2".$speciesTarget."_MergedContigs.fa";
my $mergedRealNames = "$finalDir/".$querySpecies."2".$speciesTarget."_MergedContigs.fa";
my $contigsToGenes = "$finalDir/".$querySpecies."2".$speciesTarget."_links.txt";
my $alignCheck = "$tmpDir/AlignmnentsInMerged.txt";
# --------------------------------------------------------
# Runs all modules (In order!)

&preparation($querySeq, $querySpecies, $targetSeq, $formatedTar, $formatedQuery, $mappingQuery);
&runBlastn($formatedQuery, $querySpecies, $BlastEval, $parallel, $BlastOut);
&sortBlastOut($formatedQuery, $querySpecies, $BlastOut, $NoHitsOut, $HitSeqOut, $hitDiff, $formatedTar, $HitGenes, $tmpHitList);
&reciprocalBlast($HitGenes, $querySpecies, $BlastEval, $parallel, $RecipBlastOut);
&compareBlast($RecipBlastOut, $tmpHitList, $tmpRecHitList, $BlastEval);
#sleep 2;
&saveFoundGenes($querySpecies,$HitSeqOut, $BlastOut, $tmpRecHitList, $FullOutput, $FullMapTable);
&mergeOverlap($HitSeqOut, $FullMapTable, $Kmer, $mergedOut, $alignCheck);
&mapBack($mergedOut, $mappingQuery, $mergedRealNames, $contigsToGenes);
#&cleanUp($dataDir, $tmpDir, $dbDir);	#Removing temporary files and reformated data and blast files (can be excluded)


$time = time-$time;
my $hrs = int($time/3600);
my $min = int(($time-$hrs*3600)/60);
my $seq = $time-$hrs*3600-$min*60;
print "Done!\nTotal time elapsed: $hrs h, $min min and $seq seconds\n";
# --------------------------------------------------------
# Subroutines

sub usage {
	print "\ntranscriptBlastPipe.pl
 written by Linnéa Smeds june 2010, modified aug 2010
 ==========================================================
 Usage: 
 perl transcriptBlastPipe.pl fastafile speciesDir overlap \"-a8\"
 ==========================================================
 Description:
 Blasts a file with assembled contigs or scaffolds against
 a set of reference genes (with or without UTRs). 
 Both query and target file must be in fasta-format, and
 the target file should have a header starting with gene no
 and transcript no separated with \"|\":
 	>ENSTGUG00000000001|ENSTGUT00000000001|...
 (The target file cannot contain overlapping reads. By 
 first running the script CheckOverlaps.pl, such genes
 can be removed).
 The current directory should contain a sub folder for the 
 query species (with its fasta file), and the target file
 should be placed in another folder called \"data\". The 
 script can be placed in the current directory, or anywhere
 (but then the path must be given in the command).
 ==========================================================
 Input files: 
 fastafile - with the sequences for the query species
 speciesDir - the sub dir where the fasta file is located
 overlap - overlap for 'merging' two contigs into one hit, usually k-mer size
 parallel - (optional) \"-a\" and the no of processors if the 
 		blast is to be run in parallel. Eg \"-a8\".\n\n";
	exit;
}

sub cleanUp {
	print "Remove temporary files...\n";
	system("rm -r @_");
}

sub reverseSeq {
	my $seq = shift;
	$seq =~ tr/ATCG/TAGC/;
	$seq = reverse($seq);

	return $seq;
}	

sub mapBack {
	my $merged = shift;
	my $mapFile = shift;
	my $newOut = shift;
	my $connectFile = shift;

	my %mapping = ();
	open(MAP, $mapFile);
	while(<MAP>) {
		chomp($_);
		$_ =~ s/>//g;
		my @tab = split("\t", $_);
		$mapping{$tab[1]}=$tab[0];
	}
	close(MAP);

	open(IN, $merged);
	open(OUT, ">$newOut");
	open(CON, ">$connectFile");
	while(<IN>) {
		if($_ =~ m/^>/) {
			chomp($_);
			my @tab = split(/\t/, $_);
			print OUT $tab[0]."\n";
			print CON $tab[0]."\t";
			my @contigs = split(/\s+/, $tab[1]);
			for(my $i=0; $i<scalar(@contigs); $i++) {
				if($contigs[$i] =~ m/-/) {
					my @combContigs = split(/-/, $contigs[$i]);
					print CON $mapping{$combContigs[0]};
					for(my $j=1; $j<scalar(@combContigs); $j++) {
						print CON "-".$mapping{$combContigs[$j]};
					}
					print CON " ";
				}
				else {
					unless (defined $mapping{$contigs[$i]}) {
						print "contig ".$contigs[$i]." för gen ".$tab[0]." har problem\n";
					}
					print CON $mapping{$contigs[$i]}." ";
				}
			}
			print CON "\n";
		}
		else {
			print OUT $_;
		}
	}
	close(IN);
	close(OUT);
}
		



sub mergeOverlap {
	my $queryHits = shift;
	my $FullMap = shift;
	my $Kmer = shift;
	my $Output = shift;
	my $AlignCheckOut = shift;

	print "Checking for overlaps and merging contigs...\n";

	#Saving sequences in a hashtable
	my ($prevSeq, $prevContig) = ("","");
	my %Seqs = ();
	open(QUERY, $queryHits);
	while(<QUERY>) {
		if($_ =~ m/^>/) {
			if($prevSeq ne "") {
				$Seqs{$prevContig} = $prevSeq;
				$prevSeq = "";
			}
			my @arr = split(/>/, $_);
			$prevContig =$arr[1];
			chomp($prevContig);
		}
		else {
			chomp($_);
			$prevSeq.=$_;		
		}
	}
	close(QUERY);
	$Seqs{$prevContig} = $prevSeq;


	my %genes=();
	my ($currentGene, $currentCntgs, $currentSeq, $geneLen) = ("","","","");
	my ($currentStart, $currentEnd, $currentCntStart, $currentCntEnd, $currentLen);
	my ($alignOverlap, $otherOverlap) = (0,0);
	my $badFlag = "off";
	my $cnt = 0;
	open(IN, $FullMap);
	open(OUT, ">$Output");
	open(AL, ">$AlignCheckOut");
	while(<IN>) {
		my @a = split(/\s+/, $_);
		if ($currentGene eq "") {
			$currentGene = $a[0];
			$currentCntgs = $a[3];
			$currentStart = $a[1];
			$currentEnd = $a[2];
			$geneLen = $a[7];
			if($a[6] eq '+') {
				$currentSeq = $Seqs{$a[3]};
				$currentCntStart = $a[4];
				$currentCntEnd = $a[5];
			}
			else {
				$currentSeq = reverseSeq($Seqs{$a[3]});
				$currentCntStart = length($Seqs{$a[3]})-$a[5]+1;
				$currentCntEnd = length($Seqs{$a[3]})-$a[4]+1;
			}
			$currentLen=length($Seqs{$a[3]});
		}
		else {
			if($a[0] eq $currentGene) {
				if($badFlag eq "off") {
					$geneLen=$a[7];
					if ($a[1]>$currentEnd) {
						$currentEnd = $a[2];
						$currentCntgs .= " ".$a[3];
						if($a[6] eq '+') {
							$currentSeq.= "NNNNNNNNNN".$Seqs{$a[3]};
							$currentCntStart = $a[4];
							$currentCntEnd = $a[5];
						}
						else {
							$currentSeq.= "NNNNNNNNNN".reverseSeq($Seqs{$a[3]});
							$currentCntStart = length($Seqs{$a[3]})-$a[5]+1;
							$currentCntEnd = length($Seqs{$a[3]})-$a[4]+1;
						}
						$currentLen=length($Seqs{$a[3]});
				
					}
					else {
						if($currentEnd-$a[1]<=$Kmer) {
							my ($tempSeq, $head, $tail, $align1, $align2, $VisAlignLen, $RealAlignLen);
							my ($tempStart, $tempEnd);
							my $consensus = "";
							
							if($a[6] eq '+') {
								$tempSeq = $Seqs{$a[3]};
								$tempStart = $a[4];
								$tempEnd = $a[5];
							}
							else { 
								$tempSeq = reverseSeq($Seqs{$a[3]});
								$tempStart = length($Seqs{$a[3]})-$a[5]+1;
								$tempEnd = length($Seqs{$a[3]})-$a[4]+1;
							}
							$VisAlignLen = $currentEnd-$a[1]+1;
							$RealAlignLen = $VisAlignLen+($tempStart-1)+($currentLen-$currentCntEnd);

							if($RealAlignLen<=$Kmer) {
								
								if($RealAlignLen>length($tempSeq)){
									print "Warning in gene $currentGene: contig ". $a[3].
										" is shorter than overlap and cannot be aligned!\n".
										"Gene $currentGene is excluded.\n";
									$badFlag = "on";
									$otherOverlap++;
								}
								else {
									my $x = length($currentSeq)-$RealAlignLen;
									$head=substr($currentSeq, 0, length($currentSeq)-$RealAlignLen);
									$align1 = substr($currentSeq, length($currentSeq)-$RealAlignLen, $RealAlignLen);
									$align2 = substr($tempSeq, 0, $RealAlignLen);
									$tail = substr($tempSeq, $RealAlignLen, length($tempSeq)-$RealAlignLen);
									for(my $i=0; $i<$RealAlignLen; $i++) {
										if(substr($align1,$i,1) eq substr($align2,$i,1)) {
											$consensus .= substr($align1,$i,1);
										}
										else {
											$consensus .= "N";
										}
									}
									#Extra Output to check alignments
									print AL "Gene $currentGene: merging $currentCntgs with ".$a[3]."\n";
									print AL "\tVisible align length: $VisAlignLen\n";
									print AL "\tReal align length: $RealAlignLen\n";
									print AL "\tLength of previous contig: $currentLen and this contig: ".length($tempSeq)."\n";
									print AL "\tStart and stop for previous contig: $currentCntStart and $currentCntEnd\n";
									print AL "\tand  for this contig: $tempStart and $tempEnd\n";
									print AL "\tThe full contig is before this merging ".length($currentSeq)." bp\n";
									print AL "\tThe alignment starts on pos $x on the first contig\n";
									print AL "\tand ends on pos $RealAlignLen on the second contig\n";
									print AL "\tAlignment1: $align1\n";
									print AL "\tAlignment2: $align2\n";
									print AL "\tConsensus: $consensus\n";
									$currentEnd = $a[2];
									$currentCntgs .= "-".$a[3];
									$currentSeq = $head.$consensus.$tail;
									$currentCntStart = $tempStart;
									$currentCntEnd = $tempEnd;
									$currentLen = length($Seqs{$a[3]});
									$alignOverlap++;
								}
								
							}
							else {
								$badFlag = "on";
								$otherOverlap++;
							}
						}
						else {
							$otherOverlap++;
							$badFlag = "on";
						}
						
					}
				}
			}
			else {
				if($badFlag eq "off") {
					print OUT ">".$currentGene."|".$currentStart."|".$currentEnd."|".$geneLen."\t".$currentCntgs."\n".
					$currentSeq."\n";
					$cnt++;
				}
				$currentGene = $a[0];
				$currentCntgs = $a[3];
				$currentStart = $a[1];
				$currentEnd = $a[2];
				$geneLen=$a[7];
				if($a[6] eq '+') {
					$currentSeq = $Seqs{$a[3]};
					$currentCntStart = $a[4];
					$currentCntEnd = $a[5];
				}
				else {
					$currentSeq = reverseSeq($Seqs{$a[3]});
					$currentCntStart = length($Seqs{$a[3]})-$a[5]+1;
					$currentCntEnd = length($Seqs{$a[3]})-$a[4]+1;
				}
				$currentLen=length($Seqs{$a[3]});
				$badFlag="off";
			}
			
		}
	}
	if($badFlag eq "off") {
		$cnt++;
	}
	print "...$cnt genes in the merged file.\n";
	print "...$alignOverlap cases of overlaps where the contigs could be merged.\n";
	print "...$otherOverlap genes were removed due to large overlaps between contigs.\n";
}	

sub saveFoundGenes {
#	my $query = shift;
	my $dir = shift;
	my $queryHits = shift;
	my $Blast = shift;
	my $HitList = shift;
	my $Output = shift;
	my $mapTbl = shift;

	my %FormerHits = ();
	open(HIT, $HitList);
	while(<HIT>) {
		#print "tittar på hit ";
		my @arr = split(/\t/, $_);
		chomp($arr[1]);
		#print $arr[0]."\n";
		$FormerHits{$arr[0]}=$arr[1];
	}
	close(HIT);

	print "Printing all contigs with hits...\n";
	my %savedHits = ();
	my %genes= ();
	my ($prevCntg, $prevGeneTrans, $tarStart, $tarEnd, $querStart, $querEnd, $geneLen, $signCheck) = ("","","","","","","","",0,0);
	my $hitFlag = "ok";
	my (@a, @t,);
	my $cnt = 0;
	open(BLAST, $Blast);
	while(<BLAST>) {
		@a = split(/\s+/, $_);
		@t = split(/\|/, $a[1]);

			#print "inside the blast loop\n";

		if($cnt==0) {
			$prevCntg = $a[0];
			$prevGeneTrans = $t[0]."|".$t[1];
		
			if(defined $FormerHits{$prevGeneTrans} && $FormerHits{$prevGeneTrans} =~ m/$prevCntg/) {
				$hitFlag = "ok";
				$signCheck=0;

				if($a[8]<$a[9]) {
					$tarStart = $a[8];
					$tarEnd = $a[9];
				}
				else {
					$tarStart = $a[9];
					$tarEnd = $a[8];
					$signCheck++;
				}
				$querStart = $a[6];
				$querEnd = $a[7];
				$geneLen = $t[5];
			}
			else {
				$hitFlag = "no";
			}
		}
		else {
	
			my $key = $t[0]."|".$t[1];
			my $cntg = $a[0]." ";

			#print "vi jämför ".$FormerHits{$key}." och $cntg!\n";

			if(defined $FormerHits{$key} && $FormerHits{$key} =~ m/$cntg/) {


				if($a[0] eq $prevCntg && $key eq $prevGeneTrans) {
					if($a[8]<$a[9]) {
						if($a[8]<$tarStart) {
							$tarStart = $a[8];
						}
						if($a[9]>$tarEnd) {
							$tarEnd = $a[9];
						 }
					}
					else {
						if($a[9]<$tarStart) {
							$tarStart = $a[9];
						}
						if($a[8]>$tarEnd) {
							$tarEnd = $a[8];
						 }
						$signCheck++;
					}

					if($a[6]<$querStart) {
						$querStart = $a[6];
					}
					if($a[7]>$querEnd) {
						$querEnd = $a[7];
					}
					$geneLen = $t[5];

					$hitFlag = "ok";
				}
				else {
					if($hitFlag eq "ok") {
						#print "lägger till $prevGeneTrans till hashen\n";
						$savedHits{$prevGeneTrans}{$prevCntg}{'querStart'}=$querStart;
						$savedHits{$prevGeneTrans}{$prevCntg}{'querEnd'}=$querEnd;
						$savedHits{$prevGeneTrans}{$prevCntg}{'tarStart'}=$tarStart;
						$savedHits{$prevGeneTrans}{$prevCntg}{'tarEnd'}=$tarEnd;
						$savedHits{$prevGeneTrans}{$prevCntg}{'geneLen'}=$geneLen;
						if($signCheck>0) {
							$savedHits{$prevGeneTrans}{$prevCntg}{'sign'}='-';
						}
						else {
							$savedHits{$prevGeneTrans}{$prevCntg}{'sign'}='+';
						}
						$genes{$prevGeneTrans}=1;
					}
					$prevCntg = $a[0];
					$prevGeneTrans = $t[0]."|".$t[1];
					$hitFlag = "ok";
					$signCheck=0;
					$geneLen=$t[5];

					if($a[8]<$a[9]) {
						$tarStart = $a[8];
						$tarEnd = $a[9];
					}
					else {
						$tarStart = $a[9];
						$tarEnd = $a[8];
						$signCheck++;
					}
					$querStart = $a[6];
					$querEnd = $a[7];
				}
			}
			else {
				if($hitFlag eq "ok") {
					#print "lägger till $prevGeneTrans till hashen\n";
					$savedHits{$prevGeneTrans}{$prevCntg}{'querStart'}=$querStart;
					$savedHits{$prevGeneTrans}{$prevCntg}{'querEnd'}=$querEnd;
					$savedHits{$prevGeneTrans}{$prevCntg}{'tarStart'}=$tarStart;
					$savedHits{$prevGeneTrans}{$prevCntg}{'tarEnd'}=$tarEnd;
					$savedHits{$prevGeneTrans}{$prevCntg}{'geneLen'}=$geneLen;
					$genes{$prevGeneTrans}=1;
					if($signCheck > 0) {
						$savedHits{$prevGeneTrans}{$prevCntg}{'sign'}='-';
					}
					else {
						$savedHits{$prevGeneTrans}{$prevCntg}{'sign'}='+';
					}
					$hitFlag = "no";
					$signCheck=0;
				}
				
			}				
		}
	$cnt++;
	}
	close(BLAST);

	if($hitFlag eq "ok") {
		#print "lägger till $prevGeneTrans till hashen\n";
		$savedHits{$prevGeneTrans}{$prevCntg}{'querStart'}=$querStart;
		$savedHits{$prevGeneTrans}{$prevCntg}{'querEnd'}=$querEnd;
		$savedHits{$prevGeneTrans}{$prevCntg}{'tarStart'}=$tarStart;
		$savedHits{$prevGeneTrans}{$prevCntg}{'tarEnd'}=$tarEnd;
		$savedHits{$prevGeneTrans}{$prevCntg}{'geneLen'}=$geneLen;
		$genes{$prevGeneTrans}=1;
		if($signCheck == 1) {
			$savedHits{$prevGeneTrans}{$prevCntg}{'sign'}='-';
		}
		else {
			$savedHits{$prevGeneTrans}{$prevCntg}{'sign'}='+';
		}
	}
	
	my %Seqs = ();
	my $prevSeq = "";
	my $prevContig = "";
	open(QUERY, $queryHits);
	while(<QUERY>) {
		if($_ =~ m/^>/) {
			if($prevSeq ne "") {
				$Seqs{$prevContig} = $prevSeq;
				$prevSeq = "";
			}
			my @arr = split(/>/, $_);
			$prevContig =$arr[1];
			chomp($prevContig);
		}
		else {
			chomp($_);
			$prevSeq.=$_;		
		}
	}
	close(QUERY);
	$Seqs{$prevContig} = $prevSeq;
	
	open(OUT, ">$Output");
	open(TBL, ">$mapTbl");
	foreach my $k (sort {$a cmp $b} keys %savedHits) {
		foreach my $c (sort {$savedHits{$k}{$a}{'tarStart'} <=> $savedHits{$k}{$b}{'tarStart'}} keys %{$savedHits{$k}}) {
			print OUT ">".$k."|".$savedHits{$k}{$c}{'geneLen'}."\t".$c."|".$savedHits{$k}{$c}{'tarStart'}."|". 
				$savedHits{$k}{$c}{'tarEnd'}."\n".$Seqs{$c}."\n";
			
			print TBL $k."\t".$savedHits{$k}{$c}{'tarStart'}."\t".$savedHits{$k}{$c}{'tarEnd'}.
				"\t".$c."\t". $savedHits{$k}{$c}{'querStart'}."\t".$savedHits{$k}{$c}{'querEnd'}.
				"\t".$savedHits{$k}{$c}{'sign'}."\t".$savedHits{$k}{$c}{'geneLen'}."\n";
		}
	}
	close(OUT);
	close(TBL);
	my $geneCnt=0;
	foreach my $k (keys %savedHits) {
		$geneCnt++;
	}
	print "...$geneCnt hitted genes before merging\n"; 

}
sub overlap {
	my $start1 = shift;
	my $end1 = shift;
	my $start2 = shift;
	my $end2 = shift;
	
	return ($start2<=$start1 && $end2>$start1) || ($start2<=$end1 && $end2>$end1) || ($start2>=$start1 && $end2<=$end1);
}
		
		

sub compareBlast {
	my $Recip = shift;
	my $HitList = shift;
	my $RecHitList = shift;
	my $eVal = shift;

	
	my %FormerHits = ();
	open(HIT, $HitList);
	while(<HIT>) {
		my @arr = split(/\t/, $_);
		chomp($arr[1]);
		$FormerHits{$arr[0]}=$arr[1];
	}
	close(HIT);
	

	print "Comparing results...\n";
	my %hitHash=();
	my (@a, @t,);
	open(REC, $Recip);
	while(<REC>) {

		@a = split(/\s+/, $_);
		@t = split(/\|/, $a[0]);

		my $key = $t[0]."|".$t[1];
		my $cntg = $a[1]." ";
		my $badFlag = "off";
		my $xistFlag = "off";

		if(defined $hitHash{$key}) {
			foreach my $k2 (keys %{$hitHash{$key}}) {
				if($k2 eq $cntg) {
					if ($a[6]<$hitHash{$key}{$k2}{'start'}) {
						$hitHash{$key}{$k2}{'start'}=$a[6];
					}
					if ($a[7]>$hitHash{$key}{$k2}{'end'}) {
						$hitHash{$key}{$k2}{'end'}=$a[7];
					}
					$xistFlag = "on";
				}
				else {
					if($FormerHits{$key} =~ m/$k2/) {
						if(overlap($a[6],$a[7],$hitHash{$key}{$k2}{'start'},$hitHash{$key}{$k2}{'end'})) {
							if(abs($a[9]-$hitHash{$key}{$k2}{'e'})<$eVal) {
								$badFlag = "on";
								$hitHash{$key}{$k2}{'status'}='bad';
							}
						}
					}
				}
			}
		}
		unless($xistFlag eq "on") {
			$hitHash{$key}{$cntg}{'start'}=$a[6];
			$hitHash{$key}{$cntg}{'end'}=$a[7];
			$hitHash{$key}{$cntg}{'e'}=$a[9];
			if($badFlag eq "on") {
				$hitHash{$key}{$cntg}{'status'}='bad';
			}
			else {
				$hitHash{$key}{$cntg}{'status'}='ok';
			}
		}
	}
	close(REC);

	open(LST, ">$RecHitList");
	foreach my $k (sort keys %FormerHits) {
		my @arr = split(/ /, $FormerHits{$k});
		my $badFlag = "off";
		my $temp = $k."\t";
		foreach(@arr) {
			my $cntg = $_." ";
			if(defined $hitHash{$k}{$cntg}) {
				if($hitHash{$k}{$cntg}{'status'} eq 'ok') {
					$temp.=$_." ";
				}
				elsif($hitHash{$k}{$cntg}{'status'} eq 'bad') {
					$badFlag = "on";
				}
			}
		}
		unless($badFlag eq "on") {
			print LST $temp."\n";
		}
	}
	close(LST);
}

sub reciprocalBlast {
	my $recQuery = shift;
	my $dir = shift;
	my $blastEvalue = shift;
	my $paral = shift;
	my $blastOut = shift;
	
	print "Performing reciprocal blastn...\n";
	system("blastall -p blastn -d $dir/db/$dir"."_query -i $recQuery -m 8 $paral -e $blastEvalue >$blastOut");
}

sub sortBlastOut {
	my $querySeq = shift;
	my $dir = shift;
	my $blastOut = shift;
	my $noHits = shift;
	my $Hits = shift;
	my $eValthres = shift;
	my $target = shift;
	my $newTarget = shift;
	my $HitList = shift;

	print "Sorting query file with respect to Blast output...\n";	
	
	my %CntgsWithHits=();
	my %HitGenes=();
	my %BadHitCntgs=();

	
	# Goes through all lines and saves contigs with hits, contigs with several hits, 
	# and also the hitted target genes.
	open(BLAST, $blastOut);

	my ($prevCntg, $prevGene, $prevTrans, $prevEval) = ("","","",100);
	my $hitFlag = "ok";
	my (@a, @t,);
	while(<BLAST>) {
		@a = split(/\s+/, $_);
		@t = split(/\|/, $a[1]);
		if($prevCntg eq "") {
			$prevCntg = $a[0];
			$prevGene = $t[0];
			$prevTrans = $t[1];
			$prevEval = $a[10];
		}
		else {
			if($a[0] eq $prevCntg) {
				if($t[0] eq $prevGene) {
					next;
				}
				else {
					my $diff = abs($a[10]-$prevEval);
					if($diff<$eValthres) {
						$hitFlag = "no";
						my $thresdiff = $eValthres - $diff;
						next;
					}
				}
			}
			else {
				if($hitFlag eq "no") {
					$BadHitCntgs{$prevCntg}=1;
				}
				else {
					$CntgsWithHits{$prevCntg}=1;
					my $key = $prevGene."|".$prevTrans;
					$HitGenes{$key}.="$prevCntg ";
				}
				$hitFlag = "ok";
				$prevCntg = $a[0];
				$prevGene = $t[0];
				$prevTrans = $t[1];
				$prevEval = $a[10];
				
			}
		}
	}
	if($hitFlag eq "no") {
		$BadHitCntgs{$a[0]}=1;
	}
	else {
		$CntgsWithHits{$a[0]}=1;
		my $key = $t[0]."|".$t[1];
		$HitGenes{$key}.="$prevCntg ";
		
	}
	close(BLAST);

	open(QUERY, "$querySeq");
	open(NOH, ">$noHits");
	open(HIT, ">$Hits");

	# Prints contigs without hits to one file,
	# and hitted target genes to another.
	my $which_flag = "hit";
	my ($noCnt, $hitCnt, $badhitCnt)=(0,0,0);
	while(<QUERY>) {
		if($_ =~ m/^>/) {
			my @h = split(/>/, $_);
			chomp($h[1]);
			unless(defined $CntgsWithHits{$h[1]} || defined $BadHitCntgs{$h[1]}) {
				print NOH $_ ;
				$which_flag="no";
				$noCnt++;
			}
			else {
				if(defined $CntgsWithHits{$h[1]}) {
					print HIT $_;
					$which_flag = "hit";
					$hitCnt++;
				}
				else {
					$which_flag = "badhit";
					$badhitCnt++;
				}
			}
		}
		else {
			if($which_flag eq "no") {
				print NOH $_;
			}
			elsif($which_flag eq "hit") {
				print HIT $_;
			}
		}
	}
	print "...$hitCnt contigs with approved hits\n";
	print "...$badhitCnt contigs hitting multiple genes\n";
	print "...$noCnt contigs with no hits at all\n";
	close(QUERY);
	close(NOH);
	close(HIT);

	open(TAR, "$target");
	open(LST, ">$HitList");
	open(NEW, ">$newTarget");
	
	while(<TAR>) {
		if($_ =~ m/^>/) {
			my @h = split(/[>\|]/, $_);
			my $key = $h[1]."|".$h[2];
			if (defined $HitGenes{$key}) {
				print NEW $_;
				print LST $key . "\t" . $HitGenes{$key} . "\n";
				$which_flag = "hit";
			}
			else {
				$which_flag = "no";
			}
		}
		else {
			if($which_flag eq "hit") {
				print NEW $_;
			}
		}
	}
	close(TAR);
	close(LST);
	close(NEW);
	
}

sub runBlastn {
	my $querySeq = shift;
	my $dir = shift;
	my $blastEvalue = shift;
	my $paral = shift;
	my $blastOut = shift;
	#print "The following stuff is used:\ndir: $dir \nquerySeq: $querySeq\nblastEvalue: $blastEvalue\n";
	#print "paral: $paral \nblastOut: $blastOut\n";
	
	print "Performing blastn...\n";
	system("blastall -p blastn -d $dir/db/$dir"."_target -i $querySeq -m 8 $paral -e $blastEvalue >$blastOut");
}


sub preparation {
	my $query = shift;
	my $dir = shift;
	my $targetSeq = shift;
	my $reformTar = shift;
	my $reformQuery = shift;
	my $mappingQuery = shift;

	print "Creating directories...\n";
	system("mkdir -p $dir/results/");
	system("mkdir -p $dir/data/");
	system("mkdir -p $dir/db/");
	system("mkdir -p $dir/final/");
	system("mkdir -p $dir/tmp/");

	print "Reformating target file...\n";
	open(OUT, ">$reformTar");
	open(IN, $targetSeq);
	my ($head, $seq) = ("","");
	my $cnt =0;
	while(<IN>) {
		if($_ =~ m/^>/) {
			if($seq ne "") {
				print OUT ">".$head."\n".$seq."\n";
				$seq="";
				$cnt++;
			}
			$head = $_;
			chomp($head);
			$head =~ s/" "/_/;
			$head =~ s/>//g;
		}
		else {
			chomp($_);
			$seq.=$_;
		}
	}
	if($seq ne "") {
		print OUT ">".$head."\n".$seq."\n";
		$cnt++;
	}
	print "...$cnt target sequences reformated.\n";
	close(OUT);
	close(IN);

	print "Reformating query file...\n";
	open(OUT, ">$reformQuery");
	open(MAP, ">$mappingQuery");
	open(IN, "$query");
	($head, $seq) = ("","");
	my $oldhead = "";
	$cnt=0;
	while(<IN>) {
		if($_ =~ m/^>/) {
			if($seq ne "") {
				print OUT $head."\n".$seq."\n";
				print MAP $oldhead."\t".$head."\n";
				$seq="";
				$cnt++;
			}
			my $no=$cnt+1;
			$head = ">contig".$no."X";
			$oldhead = $_;
			chomp($oldhead);
		}
		else {
			chomp($_);
			$seq.=$_;
		}
	}
	if($seq ne "") {
		print OUT $head."\n".$seq."\n";
		print MAP $oldhead."\t".$head."\n";
		$cnt++;
	}
	print "...$cnt query sequences reformated.\n";
	close(OUT);
	close(IN);
	
	print "Building Target database...\n";
	system("formatdb -t target -i $reformTar -p F -n $dir"."_target");
	system("mv $dir"."_target* $dir/db");
	print "Building Query database...\n";
	system("formatdb -t query -i $reformQuery -p F -n $dir"."_query");
	system("mv $dir"."_query* $dir/db");
	system("rm formatdb.log");

}


