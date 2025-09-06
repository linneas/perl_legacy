#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# recreateHaplotypesFromHaploidOffspring.pl
# written by Linnéa Smeds					  13 Sept 2016
# ---------------------------------------------------------
# DESCRIPTION:
# Takes a filtered file with several (haploid) offspring 
# and tries to infer the two haplotypes in the mother.
# Also fills in the missing genotypes with the most likely GT,
# (always compared to the previous line).
#
# DISCLAMER! If the same individual has two missing genotypes
# on the two first rows, the script fails to reconstruct the
# missing GT (on both lines). This can be avoided by filling
# in missing GT on the first line by hand!	
#
#### Infile
# Group16 6863778 G	A	1/1	1/1	.	1/1	1/1	0/0	1/1	0/0	1/1	1/1
# Group16 6865688 A	G	1/1	1/1	1/1	1/1	1/1	0/0	.	0/0	1/1	1/1
# Group16 6865692 A	G	1/1	1/1	1/1	1/1	1/1	0/0	.	0/0	1/1	1/1
# Group16 6879762 G	A	0/0	0/0	.	0/0	0/0	1/1	0/0	1/1	0/0	0/0
# Group16 6881886 C	T	0/0	0/0	.	0/0	0/0	1/1	0/0	1/1	0/0	0/0
#
#### Outfile 1 (Infile with missing GT filled in)
# Group16 6863778 G	A	1/1	1/1	1/1	1/1	1/1	0/0	1/1	0/0	1/1	1/1
# Group16 6865688 A	G	1/1	1/1	1/1	1/1	1/1	0/0	1/1	0/0	1/1	1/1
# 
#### Outfile 2 (A file with the two haplotypes in the mother)
# Group16 6863778 G	A	1/1	0/0
# Group16 6865688 A	G	1/1 0/0
# Group16 6865692 A	G	1/1 0/0
# Group16 6879762 G	A	0/0	1/1
# Group16 6881886 C	T	0/0 1/1

# ---------------------------------------------------------
# Example 

use strict;
use warnings;
use Data::Dumper;

# Input parameters
my $FILE = $ARGV[0];
my $OUTPREF = $ARGV[1];

# Output files
my $out1=$OUTPREF.".fillmissing";
my $out2=$OUTPREF.".haplotypes";
open(OUT1, ">$out1");
open(OUT2, ">$out2");


# GO THROUGH THE FILE
open(IN, $FILE);
my $cnt=1;
my $previous=<IN>;

while(<IN>) {
	my @tab1=split(/\s+/, $previous);
	my @tab2=split(/\s+/, $_);

	my %hash =("00"=>0, "01"=>0, "10"=>0, "11"=>0); 
	my @uncert=();


	#Looking at each individual
	for(my $i=4; $i<scalar(@tab1); $i++) {
		my $tmp="";
#		print "Looking at ind $i\n";
		# First locus...
		if($tab1[$i] eq "1/1"){
			$tmp="1";
		}
		elsif($tab1[$i] eq "0/0"){
			$tmp="0"
		}
		elsif($tab1[$i] eq "."){
			push @uncert, "$i:".$tab2[$i];
			next;
		}
		else {
			die "Unknown genotype ".$tab1[$i].", line:".join(" ",@tab1)."\n";
		}
		#...and then the second one
		if($tab2[$i] eq "1/1"){
			$tmp.="1";
		}
		elsif($tab2[$i] eq "0/0"){
			$tmp.="0";
		}
		elsif($tab2[$i] eq "."){
			push @uncert, "$i:".$tab1[$i];
			next;
		}
		else {
			die "Unknown genotype ".$tab2[$i].", line:".join(" ",@tab2)."\n";
		}
	#	print "\nAdd $tmp to hash!\n";
		$hash{$tmp}++;
	}

	# Get the key of the two largest values of the hash=>the two haplotypes
	my $A=(sort {$hash{$b} <=> $hash{$a}} keys %hash)[0];
	my $B=(sort {$hash{$b} <=> $hash{$a}} keys %hash)[1];
	my ($atop,$abot)=split("",$A);
	my ($btop,$bbot)=split("",$B);

	

	#Fill in the missing value of the second line (if any)
	foreach my $t (@uncert) {
		my ($pos, $other)=split(/[:\/]/,$t);
#		print "Fixing Genotype, ind $pos..\n";
		if($tab1[$pos] eq ".")	{	#First line, ONLY possible for the very first line of the input!!
			#Must check the next line:
			if($other eq $abot) {	
				#Missing GT is from Haplotype A
				$tab1[$pos]=$atop."/".$atop;
			}
			elsif($other eq $bbot) {
				#Missing GT is from Haplotype B
				$tab1[$pos]=$btop."/".$btop;
			}
			else{
				print STDERR "Can't fix missing genotype on line $previous"."\n";
			}
		}
		elsif($tab2[$pos] eq ".")	{	#Missing GT in Second line
			#Must check the previous line:
			if($other eq $atop) {	
				#Missing GT is from Haplotype A
				$tab2[$pos]=$abot."/".$abot;
			}
			elsif($other eq $btop) {
				#Missing GT is from Haplotype B
				$tab2[$pos]=$bbot."/".$bbot;
			}
			else{
				print STDERR "Can't fix missing genotype on line $_"."\n";
			}
		}
		else {
			die "ABORT! Something is very wrong!!\n";
		}
	}

	# Print the first line (only first time in loop)
	if($cnt==1){
		print OUT1 join("\t",@tab1)."\n";
		print OUT2 $tab1[0]."\t".$tab1[1]."\t".$tab1[2]."\t".$tab1[3]."\t".$atop."/".$atop."\t".$btop."/".$btop."\n";
	}
	#Print current line 
	print OUT1  join("\t",@tab2)."\n";
	print OUT2 $tab2[0]."\t".$tab2[1]."\t".$tab2[2]."\t".$tab2[3]."\t".$abot."/".$abot."\t".$bbot."/".$bbot."\n";

	
	# Save the current line as "previous" So we can use for next comparison
	$previous=join("\t",@tab2);
	$cnt++;

#	print "line $cnt: haplo00:".$hash{"00"}." haplo01:".$hash{"01"}." haplo10:".$hash{"10"}." haplo11:".$hash{"11"}."\n";
#	print "Genotype A: $A Genotype B: $B\n";
#	print Dumper(\%hash);
	
}
close(IN);
close(OUT1);
close(OUT2);


