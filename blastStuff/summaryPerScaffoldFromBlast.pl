#!/usr/bin/perl


# # # # # #
# summaryPerScaffoldFromBlast.pl
# written by Linnéa Smeds		      July 2011
# =======================================================
# Takes a list with scaffold parts, top hit, e-value, 
# blast length and %identity, and also a list with sp
# class and a more specific vertebrate list, and makes 
# two summary files, one with best and second best class
# hit, for extracting contamination, and one with the
# top species, class and blast length (for making more
# detailed lists for each class).
# =======================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;


my $scafList = $ARGV[0];		#List with five columns, scaffold, top hit, 
				#e-value, align-length and %ident 
my $classList = $ARGV[1];		#Two columns; species and class
my $vertList = $ARGV[2];		#Two columns; species and subclass (only vertebrates)
my $ClassOut = $ARGV[3];		#Output with best and second best class 
my $SpeciesOut = $ARGV[4];	#output with top hit species

my %class = ();
open(IN, $classList);
while(<IN>) {
	chomp($_);
	my @tab = split(/\t/, $_);
	$class{$tab[0]}=$tab[1];
	#print "adding ".$tab[0]." with value ".$tab[1]."\n";
}
close(IN);

my %vertes = ();
open(IN, $vertList);
while(<IN>) {
	chomp($_);
	my @tab = split(/\t/, $_);
	$vertes{$tab[0]}=$tab[1];
}
close(IN);

open(OUT1, ">$ClassOut");
open(OUT2, ">$SpeciesOut");

open(IN, $scafList);
while(<IN>) {
	if($_ !~ /_/) {
		my ($scaff, $sp, $eval, $len, $ident) = split(/\t/, $_);
#		print "looking at $scaff\n";
		my %class_counter = ();
		my %sp_counter = ();
		my $partCnt=1;


		&addInfo(\%class_counter, \%class, \%vertes, \%sp_counter, $_);

		my $next = <IN>;
		my @tabs = split(/\s+/, $next);
		my ($curr, $part) = split(/_/, $tabs[0]);

		while ($curr eq $scaff && $next) {
#			print "\tlooking at ".$tabs[0]."\n";
			&addInfo(\%class_counter, \%class, \%vertes, \%sp_counter, $next);
			$partCnt++;
#			print "partcnt is $partCnt\n";
			if(eof(IN)) {
				last;
			}	
			$next = <IN>;
			@tabs =  split(/\s+/, $next);
			($curr, $part) = split(/_/, $tabs[0]);
		
		}
#		print "$curr is not equal to $scaff\n";
		seek(IN, -length($next), 1);
#		print "putting back line $next";

		#Checking the big hash for printing a table with all info
		my $cnt = 0;
		my ($topHit,$topMinE,$topMaxE,$topNum,$topLen,$secHit,$secMinE,$secMaxE,$secNum,$secLen,$noHits) = ("-","-","-","-","-","-","-","-","-","-",0);
		foreach my $key (sort {$class_counter{$b}{'num'} <=> $class_counter{$a}{'num'}} keys %class_counter) {
			if($key ne "nohit") {
				$cnt++;
				if($cnt==1) {
					($topHit, $topMinE, $topMaxE, $topNum, $topLen)=($key, $class_counter{$key}{'min_e'}, $class_counter{$key}{'max_e'}, $class_counter{$key}{'num'}, $class_counter{$key}{'len'});
				}
				elsif($cnt==2) {
					($secHit, $secMinE, $secMaxE, $secNum, $secLen)=($key, $class_counter{$key}{'min_e'}, $class_counter{$key}{'max_e'}, $class_counter{$key}{'num'},$class_counter{$key}{'len'});
				}
			}
		}
		if(defined $class_counter{'nohit'}{'num'}) {
			$noHits = $class_counter{'nohit'}{'num'};
		}
		print OUT1 "$scaff\t$topHit\t$topNum\t$topMinE\t$topMaxE\t$topLen\t$secHit\t$secNum\t$secMinE\t$secMaxE\t$secLen\t$noHits\t$partCnt\n";

		#Checking the small hash for printing a species table
		$cnt = 0;
		foreach my $key (sort {$sp_counter{$b}{'num'} <=> $sp_counter{$a}{'num'}} keys %sp_counter) {
			if($key ne "NA") {
				$cnt++;
				if($cnt==1) {
					print OUT2 $scaff."\t".$key."\t".$sp_counter{$key}{'type'}."\t".$sp_counter{$key}{'num'}."\t".$sp_counter{$key}{'len'}."\n";
				}
				if($cnt>1) {
					last;
				}
			}
		}
	}
}
close(IN);



sub addInfo {
	my $line = $_[4];
	my ($scaff, $sp, $eval, $len, $ident) = split(/\t/, $line);

	if($eval =~ m/^e/){
		$eval="1".$eval;
	}

#	print "in sub: line is $line";
	my $type;
	if(defined ${$_[1]}{$sp}) {
		if(defined ${$_[2]}{$sp}) {
			$type = ${$_[2]}{$sp};
#			print "$sp has a class $type\n";
		}
		else {
			$type = ${$_[1]}{$sp};
#			print "$sp is a $type\n";
		}	
	}
	elsif($sp eq "NA") {
		$type = "nohit";	
	}
	else {
		$type = "unknown";
#		print "$sp\tunknown type\n";
	}
#	print "type is $type\n";

	if(defined ${$_[0]}{$type}{'num'}) {
		${$_[0]}{$type}{'num'}++;
		if($type ne "nohit") {
			${$_[0]}{$type}{'len'}+=$len;
			if($eval<${$_[0]}{$type}{'min_e'}) {
				${$_[0]}{$type}{'min_e'}=$eval*1+0;
			}
			if ($eval>${$_[0]}{$type}{'max_e'}) {
				${$_[0]}{$type}{'max_e'}=$eval*1+0;
			}
		}
	}
	else {
		${$_[0]}{$type}{'num'}=1;
		if($type ne "nohit") {
			${$_[0]}{$type}{'len'}=$len;
			${$_[0]}{$type}{'min_e'}=$eval*1+0;
			${$_[0]}{$type}{'max_e'}=$eval*1+0;
		}
	}

	if(defined ${$_[3]}{$sp}{'num'}) {
		${$_[3]}{$sp}{'num'}++;
		unless($sp eq "NA") {
			${$_[3]}{$sp}{'len'}+=$len;
		}
	}
	else {
		${$_[3]}{$sp}{'num'}=1;
		${$_[3]}{$sp}{'type'}=$type;	
		unless($sp eq "NA") {
			${$_[3]}{$sp}{'len'}=$len;
		}
	}		
}





