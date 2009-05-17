#!/usr/bin/perl -w

# A script to make ID1-size tokens for beer festivals

# Configuration variables:

use Digest::MD5 qw(md5 md5_hex md5_base64);

$logo="festival-form.ps";
$festival="Cambridge Beer Festival";
$fdate="19th - 24th May 2008";
$floc="Jesus Green";
$width=3*72+(3*72/8);
$height=2*72+72/8;
$xgap=0;
$ygap=0;

$imageheight = 365;
$imagewidth = 373;

# Parse the command line options
# first word: what to print
# second word: base for numbering
# third word: number of pages to print (default 1)
# fourth word (optional): paper size

if (!defined($ARGV[0])) {
    die "Error: You must tell me what to do\n";
}

if (!defined($ARGV[1])) {
    die "Error: You must tell me where to start\n";
}

$type=$ARGV[0];
$basenum=$ARGV[1];
$pages=1;

$pages=$ARGV[2] if defined($ARGV[2]);

$papersize="a4";
$papertype="card";
$counttype=1;
if ($type eq "friday") {
    $papertype="paper";
    $papercolour="blue";
    $key="90fb51a1d4764c080317e275fd5fbc85";
} elsif ($type eq "saturday") {
    $papertype="paper";
    $papercolour="green";
    $key="0d416589a89bad8d944a91f84dbfffee";
} elsif ($type eq "staffmeal") {
    $title="Staff Meal Token";
    $papercolour="blue";
    $papertype="paper";
    @description=("Use this token to pay up to £4 for a meal;",
		  "CAMRA staff must fill in amount.","","Amount used:");
    $key="20cf2622f926dce3b7e24400bff34e47";
} elsif ($type eq "beer") {
    $title="£1 Beer Token";
    $papercolour="pale yellow/cream";
    $counttype=2;
    @description=("");
    $key="dcef031b2133c10fec5e4b1b0fa9c095";
} elsif ($type eq "staffbeer") {
    $title="Staff Beer";
    $papercolour="red";
    $counttype=2;
    @description=("Please exchange","this token for half a","pint of beer.");
    $key="6cf90927f2e341ff086c6684e179077a";
} elsif ($type eq "tradebeer") {
    $title="Trade Session";
    $papercolour="orange";
    $counttype=2;
    @description=("Please exchange","this token for half a","pint of beer or",
		  "cider.");
    $key="a469497d323cf60c5fd8e5ab8519fd87";
} elsif ($type eq "driversdrinks") {
    $title="Soft Drink";
    $papercolour="orange";
    $counttype=2;
    @description=("Designated drivers","may exchange this",
		  "token for a soft drink","at the food counter.");
    $key="1e75c280755c0239d2c5e2fc9bbb15e6";
} else {
    die "Error: I don't know how to print $type tokens.\n";
}

$papersize=$ARGV[3] if defined($ARGV[3]);

if ($papersize eq "a4") {
    $landscape=0;
    $xmargin=50;
    $ymargin=40;
    $pagewidth=595;
    $pageheight=842;
    $scale=1.00;
} elsif ($papersize eq "a5") {
    $landscape=0;
    $xmargin=36;
    $ymargin=18;
    $pagewidth=595;
    $pageheight=421;
    $scale=1.00;
} else {
    die "Error: I don't know about papersize $papersize\n";
}

# Output a Postscript preamble
open(LOGO, $logo) || die "Can't open $logo: $!\n";
while(<LOGO>) {
    print $_;
}
close(LOGO);

print "/LogoForm /CAMRA-cambridge-beerfestival-logo-2004 /Form findresource def\n";
print "/GreyLogoForm /CAMRA-cambridge-beerfestival-logo-2004-grey /Form findresource def\n";

# Output a Postscript form for an ID1-size card
if ($counttype==1) { print <<EOF;
/BadgeForm <<
   /FormType 1
   /BBox [ 0 0 $width $height ]
   /Matrix matrix
    /trsmall /Times-Roman findfont 10 scalefont
    /tr12 /Times-Roman findfont 12 scalefont
    /tb12 /Times-Bold findfont 12 scalefont
    /tb16 /Times-Bold findfont 16 scalefont
    /PaintProc {
	begin
	% the festival logo as a watermark
	gsave
            % Steve's original
	    % 114 2 div $width 2 div exch sub
	    % 142 2 div $height 2 div exch sub translate
	    % $height dup scale
	    % 1 $imagewidth div dup scale

            % attempt at being smart
	    % $height $imageheight div $imagewidth mul $width sub 2 div 0 translate
            % $height $imageheight div dup scale

            % imagewidth = 365 h 373 width = 243 h 153
            % this assumes logo aspect taller than badge aspect
            $width 2 div 0 translate
	    $height $imageheight div dup scale
            0 $imagewidth sub 2 div 0 translate
	    GreyLogoForm execform
        grestore
	% the festival logo in the top-left corner
	gsave
	    6 $height 55 sub translate
            55 dup scale
	    1 $imageheight div dup scale
            LogoForm execform
        grestore
	% draw a box around the form
	1 setlinewidth
         newpath 0 0 moveto $width 0 lineto $width $height lineto 0 $height
	    lineto closepath
	 stroke
	% the name of the festival
	gsave
	    tb12 setfont
	    ($festival) dup stringwidth
	    exch 2 div $width 50 sub 2 div 50 add exch sub
	    exch pop $height 24 sub
            moveto show
        grestore
        % its date
        gsave
            tb12 setfont
            ($fdate) dup stringwidth
            exch 2 div $width 50 sub 2 div 50 add exch sub
            exch pop $height 40 sub
            moveto show
        grestore
	% its location
	gsave
	    tb12 setfont
	    ($floc) dup stringwidth
	    exch 2 div $width 50 sub 2 div 50 add exch sub
	    exch pop $height 56 sub
	    moveto show
        grestore
EOF
}

if ($counttype==2) { print <<EOF;
/BadgeForm <<
   /FormType 1
   /BBox [ 0 0 $width $height ]
   /Matrix matrix
    /tr12 /Times-Roman findfont 12 scalefont
    /tb12 /Times-Bold findfont 12 scalefont
    /tb16 /Times-Bold findfont 16 scalefont
    /PaintProc {
	begin
	% the festival logo in the background on each token
	gsave
	    10 20 translate
	    $width 2 div 20 sub dup scale
		1 $imagewidth div dup scale
            GreyLogoForm execform
        grestore
	gsave
	    10 $width 2 div add 20 translate
	    $width 2 div 20 sub dup scale
		1 $imagewidth div dup scale
            GreyLogoForm execform
        grestore
	% draw a box around the form
	1 setlinewidth
        newpath 0 0 moveto $width 0 lineto $width $height lineto 0 $height
	    lineto closepath
	stroke
	[ 10 10 ] 0 setdash
	newpath $width 2 div 0 moveto $width 2 div $height lineto stroke
	gsave
	    tb16 setfont
	    ($title) dup stringwidth pop
	    2 div $width 4 div exch sub
	    $height 30 sub
	    moveto show
        grestore
	gsave
	    tb16 setfont
	    ($title) dup stringwidth pop
	    2 div $width 4 div exch sub $width 2 div add
	    $height 30 sub
	    moveto show
        grestore
EOF
}

# Now we have to print the body of the token
if ($type eq "friday") { print <<EOF
	% The ticket type
	gsave
	    tb16 setfont
	    (Admit One on Friday 4th) dup stringwidth
	    exch 2 div $width 2 div exch sub
	    exch pop $height 80 sub
	    moveto show
        grestore
	% The ticket price
        gsave
	    tb16 setfont
	    (Price: £2) dup stringwidth
	    exch 2 div $width 2 div exch sub
	    exch pop $height 100 sub
	    moveto show
        grestore
	% Other info
	gsave
	    trsmall setfont
	    (No ticket required 11am-3pm or 5pm-6pm) 10 25 moveto show
	    (Food: 12-2:30pm and 6-9:30pm) 10 10 moveto show
        grestore
EOF
} elsif ($type eq "saturday") { print <<EOF
	% The ticket type
	gsave
	    tb16 setfont
	    (Admit One on Saturday 5th) dup stringwidth
	    exch 2 div $width 2 div exch sub
	    exch pop $height 80 sub
	    moveto show
        grestore
	% The ticket price
        gsave
	    tb16 setfont
	    (Price: £4) dup stringwidth
	    exch 2 div $width 2 div exch sub
	    exch pop $height 100 sub
	    moveto show
        grestore
	% Other info
	gsave
	    trsmall setfont
	    (No ticket required 11am-4pm) 10 25 moveto show
	    (Food: 12-2:30pm and 6-9:30pm) 10 10 moveto show
        grestore
EOF
} else {
$yloc=80;
if ($counttype==2) { $yloc=60; }
for ($x=0; $x<$counttype; $x++)
{
    $lines=$#description;
    print "gsave\n";
    print "tr12 setfont\n";
    for ($i=0; $i<=$lines; $i++) {
	print "($description[$i]) 10 $x $width 2 div mul add ";
	$y=$height-$yloc-14*$i;
	print "$y moveto show\n";
    }
    print "grestore\n";
}
}

{print <<EOF;
    end
  }
>> def

/person /Times-Bold findfont 20 scalefont def
/job /Times-Roman findfont 14 scalefont def
/number /Times-Roman findfont 8 scalefont def

%%EndProlog
%%BeginSetup
<< /PageSize [ $pagewidth $pageheight ] /ImagingBBox null >> setpagedevice
%%EndSetup
EOF
}

$page=1;
for ($i=0; $i<$pages; $i++) {
    print "%%Page: $page $page\n";
    if ($landscape) {
	print "$pageheight 1 add 0 translate 90 rotate\n";
	print "gsave 1 setlinewidth newpath 0 0 moveto $pagewidth 0 lineto\n";
	print "$pagewidth $pageheight lineto 0 $pageheight lineto closepath\n";
	print "stroke grestore\n";
    }
    print "$scale $scale scale\n";
    print "job setfont (This should be $papercolour $papersize $papertype)\n";
    print "dup stringwidth pop 2 div $pagewidth 2 div exch sub\n";
    print "$pageheight 30 sub moveto show\n";
    for ($y=0; $ymargin+(($height+$ygap)*$y)+$height < $pageheight; $y++) {
	for ($x=0; $xmargin+(($width+$xgap)*$x)+$width < $pagewidth; $x++) {
	    $number=$basenum++;
	    $xloc=$xmargin+(($width+$xgap)*$x);
	    $yloc=$ymargin+(($height+$ygap)*$y);
	    print "gsave $xloc $yloc translate BadgeForm execform\n";
#	    if (length($person)>0) {
#		print "person setfont ($person) dup stringwidth pop\n";
#		print "2 div $width 2 div exch sub\n";
#		print "$height 2 div 10 sub moveto show\n";
#	    }
#	    print "job setfont ($job) dup stringwidth pop\n";
#	    print "2 div $width 2 div exch sub\n";
#	    print "10 moveto show\n";
	    if ($counttype==1) {
		$nhash=substr(md5_base64($key.$number.$key),0,8)."   ".$number;
		print "number setfont ($nhash) dup stringwidth pop\n";
		print "$width 10 sub exch sub\n";
		print "10 moveto show\n";
	    } else {
		$nhash=substr(md5_base64($key.$number.$key),0,8)."   ".$number;
		print "number setfont ($nhash) dup stringwidth pop\n";
		print "2 div $width 4 div exch sub 10 moveto show\n";
		$number=$basenum++;
		$nhash=substr(md5_base64($key.$number.$key),0,8)."   ".$number;
		print "($nhash) dup stringwidth pop 2 div $width 4 div\n";
		print "exch sub $width 2 div add 10 moveto show\n";
	    }
	    print "grestore\n";
	}
    }
    print "showpage\n";
    $page=$page+1;
}
print "%%EOF\n";
