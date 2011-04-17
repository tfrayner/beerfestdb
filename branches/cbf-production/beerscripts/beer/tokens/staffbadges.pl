#!/usr/bin/perl -w

# A script to make staff badges for beer festivals

# Configuration variables:

$logo="festival-form.ps";
$festival="Cambridge Beer Festival";
$datafile="staff";
$width=3*72+36;
$height=2*72;
$xgap=0;
$ygap=0;

#$imagewidth = 1294;
$imageheight = 373 * 1.5; #fiddle factor

# Read the staff file
open(STAFF, $datafile) || die "Can't open $datafile: $!\n";
while(<STAFF>) {
    s/\#.*//;
    chomp;
    if (length($_)>0) {
        $staff[++$#staff]=$_;
    }
}
close(STAFF);

# Parse the command line options
# first word: how we select what to print
#  colour  numbers  volunteers
# second word: what we print
#  colour: a colour
#  numbers: a comma-separated list of badge numbers
#  volunteers: a base number for the print run
# third word (optional): paper size (a5 or a4)

if (!defined($ARGV[0])) {
    die "Error: You must tell me what to do\n";
}

if (!defined($ARGV[1])) {
    die "Error: You must tell me how to do it\n";
}

$papertype="paper";
if ($ARGV[0] eq "colour") {
    $papersize="a4";
    $papercolour=$ARGV[1];
    foreach $person (@staff) {
	($number,$name,$job,$colour)=split(/:/,$person);
	if ($colour eq $papercolour) {
	    $badges[++$#badges]=$person;
	}
    }
} elsif ($ARGV[0] eq "numbers") {
    $papersize="a4";
    foreach $number (split(/\,/,$ARGV[1])) {
	foreach $person (@staff) {
	    ($n,$name,$job,$colour)=split(/:/,$person);
	    if ($number eq $n) {
		$badges[++$#badges]=$person;
		if (!defined($papercolour)) {
		    $papercolour=$colour;
		} elsif ($colour ne $papercolour) {
		    die "Error: mixture of badge colours in this job\n";
		}
	    }
	}
    }
} elsif ($ARGV[0] eq "volunteers") {
    $papersize="a4";
    $basenum=$ARGV[1];
    $papercolour="white";
} else {
    die "Error: I don't know what you want me to do ($ARGV[0])\n";
}
    
$papersize=$ARGV[2] if defined($ARGV[2]);

if ($papersize eq "a4") {
    $xmargin=36;
    $ymargin=18;
    $pagewidth=595;
    $pageheight=842;
} elsif ($papersize eq "a5") {
    $xmargin=36;
    $ymargin=18;
    $pageheight=421;
    $pagewidth=595;
} else {
    die "Error: I don't know about papersize $papersize\n";
}

# Output a Postscript preamble
open(LOGO, $logo) || die "Can't open $logo: $!\n";
while(<LOGO>) {
    print $_;
}
close(LOGO);

# Output a Postscript form for a badge
{print <<EOF
%%BeginResource: form BadgeForm
/BadgeForm <<
   /FormType 1
   /BBox [ 0 0 $width $height ]
   /Matrix matrix
%    /tr12 /Times-Roman findfont 12 scalefont
    /tb12 /Times-Bold findfont 12 scalefont
    /PaintProc {
	begin
	% draw a box around the form
	1 setlinewidth
        newpath 0 0 moveto $width 0 lineto $width $height lineto 0 $height
	    lineto closepath
	stroke
	% the festival logo in the top-left corner
	gsave
	    5 $height 55 sub translate
            70 $imageheight div dup scale
            /CAMRA-cambridge-beerfestival-logo-2004 /Form findresource execform
        grestore
	% the name of the festival
	gsave
	    tb12 setfont
	    62 $width $height 26 sub ($festival) lrcs
        grestore
	end
    }
>> def
%%EndResource
% Center a string
% len min max center loc
/center { exch dup 3 1 roll sub 2 div add exch 2 div sub } bind def
% Right-align a string
% xloc yloc string ralign -
/ralign { dup stringwidth pop 4 -1 roll exch sub 3 -1 roll moveto show }
bind def
% Center and show
% left right yloc string lrcs -
/lrcs { dup stringwidth pop % left right yloc string len
5 -2 roll center % yloc string xloc
3 -1 roll moveto show } bind def

/person /Times-Bold findfont 22 scalefont def
/job /Times-Roman findfont 16 scalefont def
/number /Times-Bold findfont 16 scalefont def
%%EndProlog
%%BeginSetup
<< /PageSize [ $pagewidth $pageheight ] /ImagingBBox null >> setpagedevice
%%EndSetup
EOF
}

$badge=0;
$page=1;
do {
    print "%%Page: $page $page\n";
    print "job setfont 0 $pagewidth $pageheight 24 sub\n";
    print "(This should be $papercolour $papersize $papertype) lrcs\n";
    for ($y=0; $ymargin+(($height+$ygap)*$y)+$height < $pageheight; $y++) {
	for ($x=0; $xmargin+(($width+$xgap)*$x)+$width < $pagewidth; $x++) {
	    if (!defined($basenum)) {
		if ($badge <= $#badges) {
		    ($number,$person,$job)=split(/:/,$badges[$badge++]);
		    if ($job eq "") {
			$job = "Volunteer";
		    }
		    print "% Badge for $person ($job)\n";
		} else {
		    goto end_run;
		}
	    } else {
		$number=$basenum++;
		$person="";
		$job="Volunteer";
		print "% Volunteer badge number $number\n";
	    }
	    $xloc=$xmargin+(($width+$xgap)*$x);
	    $yloc=$ymargin+(($height+$ygap)*$y);
	    print "gsave $xloc $yloc translate BadgeForm execform\n";
	    if (length($person)>0) {
		print "person setfont ($person) dup stringwidth pop\n";
		print "2 div $width 2 div exch sub\n";
		print "$height 2 div 10 sub moveto show\n";
	    }
	    print "job setfont ($job) dup stringwidth pop\n";
	    print "2 div $width 2 div exch sub\n";
	    print "10 moveto show\n";
	    print "number setfont ($number) dup stringwidth pop\n";
	    print "$width 8 sub exch sub\n";
	    print "10 moveto show\n";
	    print "grestore\n";
	}
    }
  end_run:
    print "showpage\n";
    $page=$page+1;
} while (!defined($basenum) && $badge <= $#badges);

$page=$page-1;
print "%%Trailer\n";
print "%%Pages: $page\n";
print "%%EOF\n";

