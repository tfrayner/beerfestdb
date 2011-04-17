#! /usr/bin/env python

import string

# This library implements a class that represents a cask of beer.
# Furthermore, it provides a routine to read a list of casks from a
# file into a dictionary.

# We call casks by their names rather than their sizes
units={0:"",9:"firkin",18:"kilderkin",36:"barrel",54:"hogshead",72:"butt",
	11:"eleven",22:"twentytwo"}

# Casks take up a certain amount of space on the stillage...
casksize={9:12, 18:15, 36:18, 54:30, 72:60,
	11:12,22:15}

# There are four rows of cask in each bay, numbered:
rowtxt={0:'Top Back',1:'Top Front',2:'Bottom',3:'Bottom',4:'Bottom',5:'store'}

rownametonum={'ub':0,'uf':1,'lf':2,'lm':3,'lb':4,'ff':5}
rownumtoname={0:'ub',1:'uf',2:'lf',3:'lm',4:'lb',5:'ff'}
postoname={0:'A',1:'B',2:'C',3:'D',4:'E',5:''}

beers={}

# An empty space on the stillage, possibly reserved for some sinister
# purpose
class gap:
	def __init__(self,line):
		x=string.split(line,":")
		self.id=x[0]
		self.width=string.atoi(x[1])
		self.baynum=x[2]
		self.row=x[3]
		self.pos=x[4]
		self.baynum=string.atoi(self.baynum) # Debatable
		self.pos=string.atoi(self.pos)
		self.row=rownametonum[self.row]
		self.unit=1 # dummy value
		self.beer=""
	def isplaced(self):
		return 1
	def __str__(self):
		return self.id
	def __repr__(self):
		return "res(%d,%d,%d)"%(self.pos,self.level,self.fb)
	def lastdip(self):
		return 0
	def outputstillage(self,o,width,height):
		o.write("tr12 setfont\n")
		o.write("%d %d %d (%s) lrcs\n"%
			(0,width,height/2,self.id))

class cask:
	def __init__(self,line):
		x=string.split(line,":")
		self.id=x[0]
		self.unit=string.atoi(x[1])
		self.width=casksize[self.unit]
		self.brewery=x[2]
		self.beer=x[3]
		self.abv=x[4]
		self.collection=x[5]
		self.baynum=x[6]
		self.row=x[7]
		self.pos=x[8]
		self.facing=x[9]
		self.bbeer=self.brewery+":"+self.beer
		if (beers.has_key(self.bbeer)):
			beers[self.bbeer]=beers[self.bbeer]+1
		else:
			beers[self.bbeer]=1
		self.sequence=beers[self.bbeer]
		if (len(self.baynum)>0):
			self.baynum=string.atoi(self.baynum) # Debatable
			self.pos=string.atoi(self.pos)
			self.row=rownametonum[self.row]
		else:
			self.baynum=-1
			self.pos=-1
			self.row=-1
		self.dips=[]
		self.condemned=0 # boolean
	def isplaced(self):
		if (self.pos!=-1):
			return 1
		return 0
	def adddip(self,dip):
		self.dips.append(dip)
	def amountcondemned(self):
		if (self.condemned):
			if (len(self.dips)>0):
				return self.dips[len(self.dips)-1]
			return self.unit
		return 0
	def remaining(self):
		if (self.condemned): return 0
		if (len(self.dips)>0):
			return self.dips[len(self.dips)-1]
		return self.unit
	def outputlabel(self,o,width,height):
		# A rectangle for alignment purposes
		#o.write("newpath 0 0 moveto %d 0 lineto %d %d lineto\n"%
		#	(width,width,height))
		#o.write("0 %d lineto closepath stroke\n"%height)
		# Details on each label:
		# cask id
		# brewery/beer
		# ABV we think it is
		# Bay
		# Level
		# Position and front/back
		# Ready to serve
		# Collection
		o.write("tb16 setfont 0 %d %d (%s) lrcs\n"%
			(width,height-30,self.brewery))
		o.write("tb16 setfont 0 %d %d (%s) lrcs\n"%
			(width,height-50,self.beer))
		o.write("tb18 setfont %d %d moveto (%s) show\n"%
			(0,height-70,rowtxt[self.row]))
		o.write("tr12 setfont %d %d moveto (bay) show\n"%
			(0,height-90))
		o.write("tb18 setfont %d %d moveto (%s) show\n"%
			(20,height-90,self.baynum))
		o.write("tr12 setfont %d %d moveto (position) show\n"%
			(50,height-90))
		o.write("tb12 setfont %d %d moveto (%s) show\n"%
			(0,height-105,self.facing))
		o.write("tb18 setfont %d %d moveto (%s) show\n"%
			(95,height-90,postoname[self.pos]))
		o.write("tr12 setfont %d %d moveto (%s ___ of %s) show\n"%
			(0,height-125,units[self.unit],beers[self.bbeer]))
		o.write("tr12 setfont %d %d moveto (ABV %s) show\n"%
			(0,height-140,self.abv))
		o.write("tr12 setfont %d %d moveto (Cask %s) show\n"%
			(0,height-155,self.id))
		o.write("tr12 setfont %d %d moveto (Supplier: %s) show\n"%
			(0,height-170,self.collection))

		o.write("tr12 setfont %d %d moveto (Notes:) show\n"%
			(width/2,height-70))
		o.write("tr12 setfont %d %d moveto (Ready:) show\n"%
			(width/2,height-170))
	def outputstillage(self,o,width,height):
		if (self.brewery == "(space)"):
			return
		o.write("tr12 setfont\n")
		#o.write("%d %d %d (Cask %s) lrcs\n"%
		#	(0,width,height-20,self.id))
		o.write("tb12 setfont %d %d %d (%s) lrcs\n"%
			(0,width,height-40,
			self.brewery))
		o.write("%d %d %d (%s) lrcs\n"%
			(0,width,height-60,
			self.beer))
		o.write("tr12 setfont %d %d %d (%s) lrcs\n"%
			(0,width,height-95,
			"%s"%units[self.unit]))
	def __str__(self):
		if (self.isplaced()):
			return ("%s:%d:%s:%s:%s:%s:%d:%s:%d"%
				(self.id,self.unit,self.brewery,self.beer,
				self.abv,self.collection,self.baynum,
				rownumtoname[self.row],self.pos))
		return ("%s:%d:%s:%s:%s:%s:::"%
			(self.id,self.unit,self.brewery,self.beer,
			self.abv,self.collection))
	def __repr__(self):
		return "cask(\"%s\")"%str(self)

def readcaskfile(filename):
	casklist=[]
	c=open(filename)
	for i in c.readlines():
		if (i[0]=='#'): continue
		x=cask(i)
		casklist.append(x)
	c.close()
	return casklist

def readgapfile(filename):
	gaplist=[]
	c=open(filename)
	for i in c.readlines():
		if (i[0]=='#'): continue
		x=gap(i)
		gaplist.append(x)
	c.close()
	return gaplist

def main():
	print "This is a libary for managing casks at a beer festival."

if (__name__=='__main__'): main()
