#!/usr/bin/perl

# plot_LD_along_chrom.pl
# written by Linnéa Smeds                    Sept 2011
# ====================================================
# Does exactly what the R script with the same name is 
# doing, but without having changing the code for each 
# chromosome.
# ====================================================
# usage: perl plot_GC_and_cov_along_chrom.pl <chrom> 
#		<linkage group> <pdf TRUE/FALSE>
#		<merged TRUE/FALSE>

use strict;
use warnings;


my $ListFile = $ARGV[0]; #list with all chromosomes!!!
my $windFile = $ARGV[1]; #with windows for all chromosomes!!
my $pdf = $ARGV[2];
my $merged = $ARGV[3];
my $chrom = $ARGV[4];

my $windSize = 20;
my $ymax = 0.3; 

if(($pdf ne "TRUE" && $pdf ne "FALSE") || ($merged ne "TRUE" && $merged ne "FALSE")) {
	die "Input three and four must be boolean value \"TRUE\" or \"FALSE\"\n";
}

my ($chrList, $chrWind) = ("temp.list", "temp.wind");
system("awk '(\$1==\"Chr$chrom\"){print}' $ListFile |cut -f2- >$chrList");
system("awk '(\$1==\"Chr$chrom\"){print}' $windFile |cut -f2- >$chrWind");


open(OUT, ">tempRscript.R");
#open(OUT, ">chrom".$chrom."tempRscript.R");

print OUT <<"A";

# Plotting the coverage vs GC statistics

#Clear the workspace
rm(list=ls())

# Parameters
chrom="$chrom"
windSize=$windSize	#In Kb
pdf.out="$pdf"		#Formatting for png not working too well - font size decreases
merge="$merged"		#Exon density not showed on separate plots
infile="$chrWind"	#The windows for the particular chromosome
infoList = "$chrList"	#The info of scaffolds and lengths for the particular chromosome
printwind="$windSize"
ylen=$ymax
###################################################################################################
### Preparations

# Loading table and prepare
file <- paste(infile, sep="")
list <- paste(infoList, sep="")

LST<-read.table(list, sep="\\t", header=FALSE)
TB<-read.table(file, sep="\\t", header=FALSE)
title <- paste("Chrom", chrom)

# Setting gap size and plot size
gapsize<-1000/windSize		#No of windows between scaffolds
xlen<-length(TB\$V1)+(length(LST\$V1)-1)*gapsize

# Different scales for different chroms
if(chrom=="1" | chrom=="2" | chrom=="3") {
	scale<-xlen*windSize/150000
	scaleMark<-10000/windSize
	scaleMark.name<-"10Mb"
}
if(chrom=="1A" | chrom=="1B" | chrom=="4" |  chrom=="5" | chrom=="6" | chrom=="7" | chrom=="8" |  chrom=="Z") {
	scale<-xlen*windSize/90000
	scaleMark<-10000/windSize
	scaleMark.name<-"10Mb"
}
if(chrom=="9" | chrom=="11" | chrom=="12" | chrom=="13") {
	scale<-xlen*windSize/50000
	scaleMark<-1000/windSize
	scaleMark.name<-"1Mb"
}
if(chrom=="4A" | chrom=="10" |chrom=="14" | chrom=="15" | chrom=="16" | chrom=="18" | chrom=="19" | chrom=="20") {
	scale<-xlen*windSize/30000
	scaleMark<-1000/windSize
	scaleMark.name<-"1Mb"
}
if(chrom=="17" |chrom=="21" | chrom=="22" | chrom=="23" | chrom=="24" | chrom=="25" ) {
	scale<-xlen*windSize/20000
	scaleMark<-1000/windSize
	scaleMark.name<-"1Mb"
}
if(chrom=="26" | chrom=="27" | chrom=="28") {
	scale<-xlen*windSize/10000
	scaleMark<-1000/windSize
	scaleMark.name<-"1Mb"
}	

###################################################################################################
# The two plot alternatives: separate or merged plots
if(merge==FALSE) {

	# Open outfile	
	if(pdf.out==TRUE) {
		outfile <- paste("chrom",chrom,"_LD_sep_",windSize,"kb_windows.pdf",sep="")
		wid<-11*scale
		pdf(outfile,width=wid,height=5.5)
		headPos<-11
	}else {
		outfile <- paste("chrom",chrom,"_LD_sep_",windSize,"kb_windows.png",sep="")
		wid<-1000*scale
		png(outfile,width=wid,height=500)
		headPos<-15
	}
	#show(outfile)
	###############################################################################################
	### Parameter Settings
	par(oma=c(0,0,0,0)) 	#Outer margin (bottom, left, top, right)
	par(mgp=c(1.5,0.5,0))	#Where to put the lables (first=how far from axis to put the labels, 
				#middle= how far from axis to put the values, last= how far from plot 
				#to put the axis (default=0))
	par(mar=c(0.2,3,5,3))	#Plot margin
	par(mfrow=c(2,1))	#No of plots on same side (2,2) means 2*2 = 4) 
	par(cex.main=0.9, cex.axis=0.70, cex.lab=0.8, las=1)
	#par(xpd=TRUE)		#Plotting in margins allowed

	###############################################################################################
	### GC and No of windows in separate plots

	#Starting with collared
	plot(1,1, type="n", xaxt="n", ylab="LD Collared", xlim=c(0,xlen), ylim=c(0,ylen))
	xstart <- 1
	for (i in 1:length(LST\$V1)) {
	#	show(xstart)
		yval<-TB\$V2[TB\$V1==levels(factor(LST\$V1[i]))]
	#	show(yval)
		if(length(yval)>0) {
			xval<-seq(xstart,length(yval)+xstart-1, 1)
	#		show(xval)
			lines(xval, yval, type="l", col="blue")
		}
		xstart<-xstart+length(yval)+gapsize
	}

	#Adding scale
	segments(1, ylen*0.8, scaleMark+1, ylen*0.8)
	segments(1, ylen*0.82, 1, ylen*0.78)
	segments(scaleMark+1, ylen*0.82, scaleMark+1, ylen*0.78)
	text(scaleMark/2+1, ylen*0.8, labels=scaleMark.name, cex=0.8, pos=3)

	#Plotting coverage below, and the scaffold segment at bottom
	par(mar=c(5,3,0.2,3))
	par(xpd=TRUE)
	plot(1, 1, type="n", xaxt="n", ylab="LD Pied", xlab="", xlim=c(0,xlen), ylim=c(0,ylen))
	xstart <- 1
	for (i in 1:length(LST\$V1)) {
	#	show(xstart)
		yval<-TB\$V3[TB\$V1==levels(factor(LST\$V1[i]))]
	#	show(yval)
		if(length(yval)>0) {
			xval<-seq(xstart,length(yval)+xstart-1, 1)
	#		show(xval)
			lines(xval, yval, type="l", col="green")
	#		show(xstart)
	#		show(length(xval))
			segments(xstart, -ylen*0.1, length(yval)+xstart-1, -ylen*0.1)
			segments(xstart, -ylen*0.15, length(yval)+xstart-1, -ylen*0.15)
			segments(xstart, -ylen*0.1, xstart, -ylen*0.15)
			segments(length(yval)+xstart-1, -ylen*0.1, length(yval)+xstart-1, -ylen*0.15)
		}else{ 
			segments(xstart, -ylen*0.1, xstart, -ylen*0.15)
		}
		text(xstart+length(yval)/2, -ylen*0.25, labels=levels(factor(LST\$V1[i])), pos=1, srt=90, xpd=TRUE, cex=0.7) 
		xstart<-xstart+length(yval)+gapsize

	}

	#Adding scale
	segments(1, ylen*0.8, scaleMark+1, ylen*0.8)
	segments(1, ylen*0.82, 1, ylen*0.78)
	segments(scaleMark+1, ylen*0.82, scaleMark+1, ylen*0.78)
	text(scaleMark/2+1, ylen*0.8, labels=scaleMark.name, cex=0.8, pos=3)

	#Adding title
	mtext(title, side=3, line=headPos, cex=1.2, las=0)
##################################################################################################	
}else {
	# Merged Output	
	# Open outfile	
	if(pdf.out==TRUE) {
		outfile <- paste("chrom",chrom,"_",windSize,"kbWind.pdf",sep="")
		wid<-11*scale
		pdf(outfile,width=wid,height=3)
		headPos<-1
		legPos<-1.15
	}else {
		outfile <- paste("chrom",chrom,"_",windSize,"kbWind.png",sep="")
		wid<-1000*scale
		png(outfile,width=wid,height=300)
		headPos<-1
		legPos<-1.1
	}
	###############################################################################################
	### Parameter Settings
	par(oma=c(0,0,0,0)) 	#Outer margin (bottom, left, top, right)
	par(mgp=c(1.5,0.5,0))	#Where to put the lables (first=how far from axis to put the labels, 
				#middle= how far from axis to put the values, last= how far from plot
				#to put the axis (default=0))
	par(mar=c(3,3,5,3))		#Plot margin
	#par(mfrow=c(2,1))		#No of plots on same side (2,2) means 2*2 = 4) 
	par(cex.main=0.9, cex.axis=0.70, cex.lab=0.8, las=1)
	#par(xpd=TRUE)			#Plotting in margins allowed

	###############################################################################################
	### Pied and Collared in merged plot

	#Plotting both Pied and Collared at the same time
	plot(1,1, type="n", xaxt="n", ylab="LD", xlab="", xlim=c(0,xlen), ylim=c(0,ylen))
	xstart <- 1
	for (i in 1:length(LST\$V1)) {
	#	show(xstart)
		yval.col<-TB\$V2[TB\$V1==levels(factor(LST\$V1[i]))]
		yval.pied<-TB\$V3[TB\$V1==levels(factor(LST\$V1[i]))]
		if(length(yval.col)>0) {
			xval<-seq(xstart,length(yval.col)+xstart-1, 1)
	#		show(xval)
			lines(xval, yval.col, type="l", col="blue")
			lines(xval, yval.pied, type="l", col="green")
			segments(xstart, ylen*0.05, length(yval.col)+xstart-1, ylen*0.05)
			segments(xstart, ylen*0.1, length(yval.col)+xstart-1, ylen*0.1)
			segments(xstart, ylen*0.05, xstart, ylen*0.1)
			segments(length(yval.col)+xstart-1, ylen*0.05, length(yval.col)+xstart-1, ylen*0.1)
		}else{ 
			segments(xstart, ylen*0.05, xstart, ylen*0.1)
		}
		text(xstart+length(yval.col)/2, -ylen*0.15, labels=levels(factor(LST\$V1[i])), pos=1, srt=90, xpd=TRUE, cex=0.7) 
		xstart<-xstart+length(yval.col)+gapsize
	}

	#Adding scale
	segments(1, ylen*0.8, scaleMark+1, ylen*0.8)
	segments(1, ylen*0.82, 1, ylen*0.78)
	segments(scaleMark+1, ylen*0.82, scaleMark+1, ylen*0.78)
	text(scaleMark/2+1, ylen*0.8, labels=scaleMark.name, cex=0.8, pos=3)

	
	#Adding axes and title
	mtext(title, side=3, line=headPos, cex=1.2, las=0)
	legend("topright", inset=0.01, c("Col", "Pied"), col=c("blue", "green"), lty=1, cex=0.6, bty="n")
	

}
###################################################################################################
### Close the pdf
dev.off()

A

exit;

