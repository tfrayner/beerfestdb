#! /usr/bin/env python
import string
import sys
import cask
import stillage
import time
import calendar

# This program takes a cask file and tries to allocate each
# unallocated cask a position on the stillage. The shape of the
# stillage, and other constraints (reserved space, etc.) is built into
# the program.

# The program then outputs a Postscript stillage plan and cask labels.

# A "row" is a 2.5m long row of casks.  There are five "rows" per bay
# of stillage. 
class row:
	def __init__(self,baynum,row):
		self.baynum=baynum
		self.row=row
		self.casks=[None]
		self.reserved=[0,0]
		self.spaceused=0
		self.lastbeer=""
		self.currpos=0
		self.next=[]
		self.prev=None
		self.parent=None
		self.lastpos=-1
	def depthused(self,pos): # how much space used in this position for this row
		if (len(self.casks)<=pos):
			return 0
		if (self.casks[pos]!=None):
			return self.casks[pos].unit
		return 0
	def stackspace(self,cask): # is there space to stack a cask?
		if (self.row!=2):
			return 0
		if (cask.unit>22): # redundant
			return 0
		if (self.currpos>1):
			return 0
		pos=self.lastpos
		if (self.next[self.currpos].roomfor(cask)==0):
			return 0
		tdepthused=(self.next[0].depthused(pos)+
			self.next[1].depthused(pos)+self.depthused(pos))
		return (tdepthused+cask.unit<=36)
	def roomfor(self,cask):
		# non-kils must go on the bottom
		if (cask.unit!=18 and self.row<2):
			return 0
		if (((cask.width+self.spaceused)<=stillage.maxspace) or 
			(self.stackspace(cask) and cask.beer==self.lastbeer)):
			return 1
		return 0
	def reserve(self,amount,lr):
		self.spaceused=self.spaceused+amount
		self.reserved[lr]=self.reserved[lr]+amount
# Do we want to be able to add to left/right?
	def freepos(self): # first free position
		a=self.casks.count(None)
		if (a==0 or self.casks[-1]!=None):
			return len(self.casks)
		i=self.casks.index(None)
		return i
	def isfree(self,pos):
		if (self.freepos()<=pos):
			return 1
		if (self.casks[pos]==None):
			return 1
		return 0
	def add(self,cask,pos=-3):
		auto=0
		if (pos==-3):
			self.casks.append(None)
			pos=self.lastpos+1
			auto=1
		# If there's not enough space in the casks list then
		# append None objects until there is (plus one more)
		while (len(self.casks)<=pos):
			self.casks.append(None)
		if (auto and pos>0 and self.stackspace(cask) and cask.beer==self.lastbeer):
			# check if room on top
			if (cask.unit==18 and pos<4 and self.prev.isfree(pos-1) and self.prev.roomfor(cask)):
				pos=pos-1
				self.prev.add(cask,pos)
			else:
				# stack behind existing cask
				pos=pos-1
				self.next[self.currpos].add(cask,pos)
				self.currpos=self.currpos+1
		#elif (pos>0 and self.stackspace(cask) and self.next[0].freepos()==(pos-1) and cask.unit<=22):
		#	# shove leftover cask to space at back
		#	pos=pos-1
		#	self.next[0].add(self.casks[pos],pos)
		#	# insert this cask in its place at the front
		#	self.casks[pos]=cask
		#	cask.baynum=self.baynum
		#	cask.row=self.row
		#	cask.pos=pos
		elif (self.casks[pos]==None):
			# initialise 2d row
			self.currpos=0
			# add cask in this row
			self.casks[pos]=cask
			cask.baynum=self.baynum
			cask.row=self.row
			cask.pos=pos
			self.spaceused=self.spaceused+cask.width
		else:
			print ("duplicate cask position %d:%d:%d for cask id %s and %s"%
				(self.baynum, self.row, pos, cask.id, self.casks[pos].id))
			#print ("Replacing cask %s with cask %s"%
			#	(self.casks[pos].id,cask.id))
		if (self.row==2 and cask.unit>22):
			# add gap to next row
			self.next[0].spaceused=self.next[0].spaceused+cask.width
			self.next[1].spaceused=self.next[1].spaceused+cask.width
		self.lastbeer=cask.beer
		self.lastpos=pos
	def output(self,o,width,height):
		x=0
		pos=0
		for i in self.casks:
			if (i==None):
				if (self.row>2 and self.parent.casks[pos]!=None):
					# hack in empty space
					cw=self.parent.casks[pos].width*width/stillage.maxspace
					o.write("gsave %d 0 translate\n"%x)
					o.write("newpath %d 0 moveto %d %d lineto stroke\n"%
						(cw,cw,height))
					o.write("grestore\n")
					x=x+cw
					pos=pos+1
				elif (pos<4):
					# hack in empty space
					cw=15*width/stillage.maxspace
					o.write("gsave %d 0 translate\n"%x)
					o.write("newpath %d 0 moveto %d %d lineto stroke\n"%
						(cw,cw,height))
					o.write("grestore\n")
					x=x+cw
					pos=pos+1
				continue
			cw=i.width*width/stillage.maxspace
			o.write("gsave %d 0 translate\n"%x)
			o.write("newpath %d 0 moveto %d %d lineto stroke\n"%
				(cw,cw,height))
			i.outputstillage(o,cw,height)
			o.write("grestore\n")
			x=x+cw
			pos=pos+1

# A "bay" is a collection of three rows, i.e. a section of stillage.
class bay:
	def __init__(self,baynum):
		self.rows=[row(baynum,0),row(baynum,1),
			row(baynum,2),row(baynum,3),row(baynum,4),row(baynum,5)]
		self.baynum=baynum
		self.next=0
		self.prev=0
		self.rows[2].next.append(self.rows[3])
		self.rows[2].next.append(self.rows[4])
		self.rows[2].prev=self.rows[1]
		self.rows[3].parent=self.rows[2]
		self.rows[4].parent=self.rows[2]
	def add(self,cask,row,pos):
		self.rows[row].add(cask,pos)
	def output(self,o):
		o.write("% bay output todo\n")

# Step zero: create the stillage data structure
bays={}
for i in stillage.baygroups:
	for j in xrange(i[0],i[1]+1):
		bays[j]=bay(j)
	for j in xrange(i[0]+1,i[1]):
		bays[j].next=j+1
		bays[j].prev=j-1
		bays[j-1].next=j
		bays[j+1].prev=j

# Step one: read in the casks file and build up an initial idea of
# which places are filled.
casklist=cask.readcaskfile("casklist")
casks={}
for i in casklist:
	casks[i.id]=i
	if (i.isplaced()):
		bays[i.baynum].add(i,i.row,i.pos)
		bays[i.baynum].rows[i.row].lastpos=-1 # re-set counter to beginning

# Step one and a half: read in the gaps file and fill the layout with it
gaplist=cask.readgapfile("gaplist")
for i in gaplist:
	bays[i.baynum].add(i,i.row,i.pos)

# Step one and three quarters:

# Sometimes we only want to print out certain cask labels (to save
# the very expensive label stock).  If argv[1] is 'labels' then the
# label output is restricted to the following cask IDs.
printcasks=casklist
if (len(sys.argv)>1):
    if (sys.argv[1]=='labels'):
	printcasks=[]
	for i in sys.argv[2:]:
		for j in casklist:
			if (j.id==i): printcasks.append(j)

# Step two: initial layout
# This step can be skipped once initial layout is done

if 0:
    b=stillage.minbay
    rc=0
    r=[0,2,1,0,0,0]
    lastbeer=None
    for i in casklist:
	#print "Considering cask "+i.id
	beer="%s:%s"%(i.brewery,i.beer)
	if (i.isplaced()):
		#print "already placed; saving position"
		b=i.baynum
		if (i.row<=2):
			rc=r.index(i.row)
		else:
			rc=0
		# update lastpos
		bays[b].rows[r[rc]].lastpos=i.pos
		bays[b].rows[r[rc]].lastbeer=i.beer
		if (r[rc]<=2 and r[rc]<=4): # ugh!
			bays[b].rows[2].currpos=(r[rc]-2)
	else:
		#print "not placed"
		# If same beer as last placed beer, try the current row, and
		# the same row in the next bay.  If this doesn't work then
		# try other rows in the current bay, then give up.
		if (beer==lastbeer):
			#print "same as last"
			if (bays[b].rows[r[rc]].roomfor(i)):
				bays[b].rows[r[rc]].add(i)
			elif (bays[b].next>0 and 
				bays[bays[b].next].rows[r[rc]].roomfor(i)):
				bays[bays[b].next].rows[r[rc]].add(i)
			elif (r<2 and bays[b].rows[r[rc+1]].roomfor(i)):
				bays[b].rows[r[rc+1]].add(i)
			else:
				print "Can't place cask "+i.id
		else:
			#print "new type of beer"
			rc=0
			while (b<=stillage.maxbay and not bays[b].rows[r[rc]].roomfor(i)):
				rc=rc+1
				if (rc>=3):
					rc=0
					b=b+1
					# skip non-existant bays
					while (b<stillage.maxbay and bays.has_key(b)==0):
						b=b+1
			if (b>stillage.maxbay):
				print "got to end of bays"
				break
			bays[b].rows[r[rc]].add(i)
	lastbeer=beer

# Step three: there is no step three

# Step four: output a new casks file
if 1:
	o=open("casklist-placed",'w')
	o.write("# THIS FILE IS AUTOMATICALLY GENERATED BY layout.py\n")
	for i in casklist:
		o.write(str(i)+"\n")
	o.close()

# Step five: output a stillage layout diagram
def format((year, month, day, hour, minute)):
    return '%d %s %d %d:%d' % (day, calendar.month_name[month], year,
	hour, minute)
#todaytuple=time.localtime(time)[:5]
#todaydate=format(todaytuple)
o=open("stillage.ps",'w')
o.write("""%!PS-Adobe-3.0
%%Title: Stillage Layout
%%Creator: layout.py
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

/tr12 /Times-Roman /Font findresource 12 scalefont def
/tb12 /Times-Bold /Font findresource 12 scalefont def
/tr20 /Times-Roman /Font findresource 20 scalefont def
/tb20 /Times-Bold /Font findresource 20 scalefont def
%%EndProlog
%%BeginSetup
%%BeginFeature: *PageSize A4
<< /PageSize [595 842] /ImagingBBox null >> setpagedevice
%%EndFeature
%%EndSetup
""")

height=550
margin=120
width=842-(margin*2)
def outputbay(bay):
	o.write("%%%%Page: %d %d\n"%(bay.baynum,bay.baynum))
	o.write("595 0 translate 90 rotate\n")
	o.write("tb20 setfont\n")
	o.write("(Bay %d) dup stringwidth pop 0 842 center 560 moveto show\n"%
		bay.baynum)
	o.write("tr20 setfont\n")
	#o.write("830 560 (%s) ralign\n"%(todaydate))
	o.write("newpath 0 %d moveto 842 %d lineto stroke\n"%
		(height*3/5,height*3/5))
	def hlabel(xin,y,text):
		o.write("%d %d moveto (%s) show\n"%(xin,y,text))
		o.write("%d %d (%s) ralign\n"%(842-xin,y,text))
	hlabel(30,height*9/10,"Back")
	hlabel(15,height*8/10,"TOP")
	hlabel(30,height*7/10,"Front")
	hlabel(30,height*5/10,"Back")
	hlabel(30,height*3/10,"Middle")
	hlabel(15,height*2/10,"BOTTOM")
	hlabel(30,height*1/10,"Front")

	o.write("newpath %d 0 moveto %d %d lineto stroke\n"%
		(margin,margin,height))
	o.write("newpath %d 0 moveto %d %d lineto stroke\n"%
		(margin+width,margin+width,height))
	o.write("[1] 0 setdash\n")
	o.write("newpath %d %d moveto %d %d lineto stroke\n"%
		(margin,height*4/5,margin+width,height*4/5))
	o.write("newpath %d %d moveto %d %d lineto stroke\n"%
		(margin,height*2/5,margin+width,height*2/5))
	o.write("newpath %d %d moveto %d %d lineto stroke\n"%
		(margin,height/5,margin+width,height/5))
#	for i in xrange(1,4):
#		o.write("newpath %d 0 moveto %d %d lineto stroke\n"%
#			(margin+(i*width/4),margin+(i*width/4),height))
	# Output top rows
	for i in xrange(0,2):
		o.write("%% row %d\n"%i)
		o.write("gsave %d %d translate\n"%(margin,
			height*(4-i)/5))
		bay.rows[i].output(o,width,height/5)
		o.write("grestore\n")
	# Output bottom rows
	for i in xrange(2,5):
		o.write("%% row %d\n"%i)
		o.write("gsave %d %d translate\n"%(margin,
			height*(i-2)/5))
		bay.rows[i].output(o,width,height/5)
		o.write("grestore\n")

	o.write("showpage\n")

# We are going right-to-left this year, so low-numbered positions are at
# the right
pages=0
baylist=bays.keys()
baylist.sort()
for i in baylist:
	outputbay(bays[i])
	pages=pages+1
o.write("%%Trailer\n")
o.write("%%%%Pages: %d\n"%pages)
o.write("%%EOF\n")
o.close()

# Step six: output cask labels
o=open("labels.ps",'w')
o.write("""%!PS-Adobe-3.0
%%Title: Cask labels
%%Creator: layout.py
%%Pages: (atend)
%%LanguageLevel: 2
%%Orientation: Portrait
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

/tr12 /Times-Roman /Font findresource 12 scalefont def
/tb12 /Times-Bold /Font findresource 12 scalefont def
/tr16 /Times-Roman /Font findresource 16 scalefont def
/tb16 /Times-Bold /Font findresource 16 scalefont def
/tb18 /Times-Bold /Font findresource 18 scalefont def
/tb20 /Times-Bold /Font findresource 20 scalefont def
%%EndProlog
%%BeginSetup
%%BeginFeature: *PageSize A4
<< /PageSize [595 842] /ImagingBBox null >> setpagedevice
%%EndFeature
%%EndSetup
""")

# There are eight labels per page. They are 3+7/8in wide and 2+5/8in
# (and a bit) high. Vertically they are unseparated; there is a small
# strip down the middle of the page separating the two columns.

lwidth=279
lheight=194
xgap=10
lmargin=20
bmargin=36

page=1
x=0
y=0
d={}
def mysort(x,y):
	return (cmp(x.brewery,y.brewery) or cmp(x.id,y.id))
printcasks.sort(mysort)

for i in printcasks:
	# don't print labels for pseudo casks
	if (i.brewery == "(space)" or i.brewery =="Cooler"):
		continue
	if (x==0 and y==0):
		if (page>1):
			keys = d.keys()
			keys.sort()
			o.write("tr12 setfont 36 20 moveto (%d - %s) show\n"%(page,keys))
			o.write("showpage\n")
			d={}
		o.write("%%%%Page: %d %d\n"%(page,page))
        d[i.brewery] = 1;
	xc=lmargin+(lwidth+xgap)*x
	yc=bmargin+(lheight)*(3-y)
	o.write("gsave %d %d translate\n"%(xc,yc))
	i.outputlabel(o,lwidth,lheight)
	o.write("grestore\n")
	x=x+1
	if (x>1):
		x=0
		y=y+1
		if (y>3):
			y=0
			page=page+1

keys = d.keys()
keys.sort()
o.write("tr12 setfont 36 20 moveto (%d - %s) show\n"%(page,keys))
o.write("showpage\n")
o.write("%%Trailer\n")
o.write("%%%%Pages: %d\n"%page)
o.write("%%EOF\n")
o.close()
