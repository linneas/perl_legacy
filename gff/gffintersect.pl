#!/usr/bin/perl

$usage .= "$0 - find intersection of two GFF files\n";
$usage .= "\n";
$usage .= "Usage: $0 [-sortedname|-sortedstart|-unsorted] [-name1 name] [-quiet] [-print1] [-minfrac1 xxx] [-minfrac2 xxx] [-near xxx] [-minhits xxx] [-maxhits xxx] [-not] [-all] [-self] [-shutit] file1 file2\n";
$usage .= "\n";
$usage .= "Prints lines from file2 that intersect (or do not intersect) with file1\n";
$usage .= "\n";
$usage .= "Use -sortedname if file1 and file2 known to be sorted by <seqname> field,\n";
$usage .= " or -sortedstart (stronger, default) if also sorted in ascending order of <start> field,\n";
$usage .= " or -unsorted if not sorted at all.\n";
$usage .= "Use -name1 if file1 is a name that won't look good in \"intersect(..)=(....)\" messages (e.g. a complex pipe command)\n";
$usage .= "Use -quiet to suppress \"intersect(..)=(....)\" messages altogether\n";
$usage .= "Use -print1 to copy all lines from file1 to output\n";
$usage .= "Use -minfrac1 and -minfrac2 to specify minimum fractional overlap for file1 and file2 features respectively\n";
$usage .= "Use -near to extend definition of \"overlap\" to nearby GFFs\n";
$usage .= "Use -minhits and -maxhits to specify minimum/maximum number of hits required to print lines from file2 (default is 1)\n";
$usage .= "Use -not to print lines from file2 that don't match the criteria rather than lines that do\n";
$usage .= "Use -all to print everything from file2\n";
$usage .= "Use -self for comparisons vs self (omit file2); also adds \"self&\" prefix to name1\n";
$usage .= "Use -shutit to suppress GFF format warnings\n";
$usage .= "\n";

# By default assume files are sorted by name and sequence start number.
$sortedname = $sortedstart = 1;
$minhits = 1;

while (@ARGV) {
    last unless $ARGV[0] =~ /^-./;      # Loop thru all the command line options.
    $opt = lc shift;                    # Get lowercase version of option.
    if ($opt eq "-not") { $not = 1 }
    elsif ($opt eq "-all") { $all = 1 }
    elsif ($opt eq "-self") { $self = 1 }
    elsif ($opt eq "-quiet") { $quiet = 1 }
    elsif ($opt eq "-print1") { $print1 = 1 }
    elsif ($opt eq "-sortedname") { $sortedname = 1; $sortedstart = 0 }
    elsif ($opt eq "-sortedstart") { $sortedname = $sortedstart = 1 }
    elsif ($opt eq "-unsorted") { $sortedname = $sortedstart = 0 }
    elsif ($opt eq "-minfrac1") { defined($minfrac1 = shift) or die $usage }
    elsif ($opt eq "-minfrac2") { defined($minfrac2 = shift) or die $usage }
    elsif ($opt eq "-minhits") { defined($minhits = shift) or die $usage }
    elsif ($opt eq "-maxhits") { defined($maxhits = shift) or die $usage }
    elsif ($opt eq "-near") { defined($near = shift) or die $usage }
    elsif ($opt eq "-name1") { defined($name1 = shift) or die $usage }
    elsif ($opt eq "-shutit") { $shutit = 1 }
    else { die "$usage\nUnknown option: $opt\n" }
}

if (@ARGV==0 && $self) { die "Sorry - perl doesn't buffer STDIN, so you'll have to use a temporary file for that. Died" }
if (@ARGV==1) { push @ARGV, $self ? $ARGV[0] : '-' }
@ARGV==2 or die $usage;
($file1,$file2) = @ARGV;

$name1 = $file1 unless defined $name1;
if ($self) { $name1 = "self&$name1" }

open FILE1, $file1 or die "$file1: $!";
open FILE2, $file2 or die "$file2: $!";

# $line1 holds next line from file1; @f1 holds fields of $line1
# $line2 holds next line from file2; @f2 holds fields of $line2
# *FILE1 is a typeglob used to pass the filehandle to subroutine.
# \$n1 is a reference to $n1, which is a line number counter.
($line1,@f1) = getline(*FILE1,$file1,\$n1); 
($line2,@f2) = getline(*FILE2,$file2,\$n2);

# If files are sorted by name, store a reference to file1 array.
# Note: @file1 is an array and $file1 is a scalar.  They are different variables.
if ($sortedname) { $aref = \@file1 }

while (defined $line2) {        # outer loop is over all single successive lines in file2 
    $seqname2 = $f2[0];         # Name value from current line in file 2.

    # printbuffer1 holds lines to be printed from file1. output these now, if it's time.
    while (@printbuffer1) {
	my @f = split /\t/, $printbuffer1[0];
	# Print line from buffer1 if (name1 < name2)  OR 
	#    if (name1 == name2) AND ( (files are not sorted by start number) OR (start1 <= start2) ) 
	if ($f[0] lt $seqname2 or 
	    ($f[0] eq $seqname2 and (!$sortedstart or $f[3] <= $f2[3]))) { 
	    print shift @printbuffer1 # Print one line from buffer 
	    }
	else { 
	    last 
	    }
    }
    
    # If files are sorted by name AND name2 is new, reset the file1 array and store name2 in lastName2.
    if ($sortedname && $seqname2 ne $lastseqname2) { 
	@file1 = (); 
	$lastseqname2 = $seqname2 
	}

    # Get lines from file1 and push GFF coords onto file1 stack.
    #
    # If pre-sorted by name ($sortedname=1) and start point ($sortedstart=1), store in file1 array the gff coords where 
    #    seqname1=seqname2 and there is overlap between file1 coords and file2 coords.
    # If $sortedname=1 and $sortedstart==0, store in file1 array the gff coords where seqname1=seqname2 and do not check
    #    for overlap.
    # If $sortedname=0, push all GFF coords into file1 hash.
    #
    # The coords on the @file1 (or @{$file1{$seqname1}}) stack are strings of the form "start end linenumber"
    # ...this is so that they are fast to sort by scalar numeric value
    #
    while (defined($line1) and $seqname1 = $f1[0], # seqname1 is assigned here 
	   (!$sortedname or $seqname1 lt $seqname2 or 
	    ($seqname1 eq $seqname2 and (!$sortedstart or $f1[3] - $near <= $f2[4])))) {
	if ($sortedname) {
	    if ($seqname1 eq $seqname2) { 
		# In this context, file1 is an array.
		push @file1, "@f1[3,4] $n1" # start, end, line number
		} 
	} 
	else {
            # In this context, file1 is a hash with key = seqname1 and value = anonymous array reference.
	    push @{$file1{$seqname1}}, "@f1[3,4] $n1"; 
	}
	$arefsorted = 0;

	# put lines from file1 into file1 printing buffer if -print1 switch is set
	if ($print1) {
	    if (!$sortedname or $seqname1 lt $seqname2 or ($seqname1 eq $seqname2 and (!$sortedstart or $f1[3] <= $f2[3]))) { 
		print $line1 
		}
	    else { 
		push @printbuffer1, $line1 
		}
	}
	($line1,@f1) = getline(*FILE1,$file1,\$n1);
    }

    # $aref is a reference to the array that holds the GFF coords for lines from file1.
    # this array must be sorted by startpoint - do this now if necessary
    #
    unless ($sortedname) { $aref = $file1{$seqname2} } # file1 hash is accessed
    unless ($arefsorted) {
	unless ($sortedstart) { @$aref = sort {$a<=>$b} @$aref }
	$arefsorted = 1;
    }

    # Loop over every entry in @$aref until past $line2 endpoint.
    # $skip and $hitstart2yet are used to keep track of entries in @$aref that may be discarded:
    # while the $hitstart2yet flag is FALSE, $skip is incremented and later used to discard passed $line1's
    #
    @lines = ();
    $hitstart2yet = $skip = 0;
    ($start2,$end2) = @f2[3,4];
    for ($i=0;$i<@$aref;$i++) {
	$entry1 = $aref->[$i];
	last if $entry1 - $near > $end2;
	($start1,$end1,$n) = split /\s+/, $entry1;  # parse the "start end linenumber" string

	# check for entries that may be discarded
	#
	if ($end1 + $near < $start2) { # No overlap between line1 and line2
	    if ($sortedstart and !$hitstart2yet) { $skip = $i + 1 }
	} else {

	    # if line from file1 overlaps line from file2, store linenumber in @lines array
	    #
	    $hitstart2yet = 1;
	    # the "-near" switch extends our concept of "overlap" to nearby GFFs
	    # to do this, we calculate effective start and end points for 
	    ($effstart1,$effend1) = ($start1-$near/2,$end1+$near/2);
	    ($effstart2,$effend2) = ($start2-$near/2,$end2+$near/2);
	    $maxstart = $effstart1 > $effstart2 ? $effstart1 : $effstart2;
	    $minend = $effend1 < $effend2 ? $effend1 : $effend2;
	    $overlaplen = $minend + 1 - $maxstart;
	    $len1 = $effend1 + 1 - $effstart1;
	    $len2 = $effend2 + 1 - $effstart2;
	    if (($len1 && $overlaplen/$len1 >= $minfrac1) && ($len2 && $overlaplen/$len2 >= $minfrac2)) {
		push @lines, $n; # Save line number from file 1
	    }
	}
    }
    while ($skip-- > 0) { shift @$aref }

    # print if eligible
    #
    if (defined $maxhits) { 
	$test = (@lines >= $minhits && @lines <= $maxhits) 
	}
    else { 
	$test = (@lines >= $minhits) 
	}
    # $all==1 means print all lines from file2
    # $not==1 means print lines from file2 which don't match the criteria
    if ($test && ($all || !$not)) {
	if ($quiet) { print $line2 }
	else {
	    chomp $line2;
	    print "$line2 intersect($name1)=(@{[sort {$a<=>$b} @lines]})\n";
	}
    } elsif (!$test && ($all || $not)) {
	print $line2;
    }

    ($line2,@f2) = getline(*FILE2,$file2,\$n2);
} # while (defined $line2)

print $line1 if $print1 && defined $line1;

close FILE2;
close FILE1;

sub getline {
    local (*FH) = shift;   # Make a local copy of the filehandle typeglob.
    my ($file,$nref) = @_; # @_ contains the rest of the subroutine arguments: filename and a reference to a counter
    my $line;              # Initially is undefined.
    # Iterate if $line is undefined or does not contain non-whitespace characters.
    while (!defined($line) || $line !~ /\S/) { 
	$line = <FH>;      # Get next line from the file.
	$line =~ s/\#.*//; # Remove comments from $line.
	++$$nref;          # Increment line number counter.
	last if !defined($line) 
	}
    my @f = split(/\t/,$line,9); # split line into 9 tab separated fields
    if (@f == 0) { return (undef) }
    if (!$shutit) {
	if (@f < 9) { warn "Warning: fewer than 9 fields at $file line $$nref\n" }
	if (join("",@f[0..7]) =~ / /) { warn "Warning: space in tab-delimited field at $file line $$nref\n" }
    }
    ($line,@f); # Return the line and the fields.
}

