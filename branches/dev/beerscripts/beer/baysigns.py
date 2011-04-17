#! /usr/bin/env python
import string
import sys

o=open("baysigns.ps",'w')
o.write("""%!PS-Adobe-3.0
%%Title: Stillage Bay Signs
%%Creator: baysigns.py
%%Pages: (atend)
%%LanguageLevel: 2
%%Orientation: Landscape
%%EndComments
%%BeginProlog
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

/tb /Times-Bold /Font findresource 350 scalefont def
%%EndProlog
%%BeginSetup
%%BeginFeature: *PageSize A4
<< /PageSize [595 842] /ImagingBBox null >> setpagedevice
%%EndFeature
%%EndSetup
""")

def page(num,contents):
	o.write("%%%%Page: %d %d\n"%(num,num))
	o.write("595 0 translate 90 rotate\n")
	# Vertical line up middle
	o.write("newpath 421 0 moveto 421 595 lineto stroke\n")
	# Left,right contents
	o.write("tb setfont 0 421 175 (%s) lrcs 421 842 175 (%s) lrcs\n"%
		(contents[0],contents[1]))
	o.write("showpage\n")

p=1
pdat=[	("","1"),
	("1","2"),
	("2","3"),
	("3",""),
	("","4"),
	("4","5"),
	("5","6"),
	("6","7"),
	("7","8"),
	("8","9"),
	("9","10"),
	("10","11"),
	("11",""),
	("","12"),
	("12","13"),
	("13","14"),
	("14","15"),
	("15","16"),
	("16","17"),
	("17",""),
	("","18"),
	("18","19"),
	("19","20"),
	("20","21"),
	("21",""),
	("","22"),
	("22","23"),
	("23","24"),
	("24","25"),
	("25","26"),
	("26","27"),
	("27","28"),
	("28","29"),
	("29","30"),
	("30","31"),
	("31","32"),
	("32","33"),
	("33","")
       ]

for i in pdat:
	page(p,i)
	p=p+1

o.write("%%%%Trailer\n%%%%Pages: %d\n%%%%EOF\n"%(p-1))
o.close()
