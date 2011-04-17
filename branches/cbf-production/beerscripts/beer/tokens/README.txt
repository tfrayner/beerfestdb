These are the scripts for generating festival tokens and badges.

To generate staff badges:
perl staffbadges.pl volunteers 1 > badges.ps

To generate staff beer tokens:
perl id1.pl staffbeer 1 > staffbeer.ps

There are other types of token available - see the script for details.

The logo can be changed by updating festival-form.ps. Unfortunately you have
to edit the postscript by hand! Details below:

================================================================================
open the image in GIMP, convert to greyscale and save as .ps
open this file and festival-form.ps in text editor(s)
copy and paste the image data into festival-form.ps. The image data is the 
random looking garbage like this:
/LogoImageSmall currentfile /ASCII85Decode filter readin
W;d&"s8W#sqXFLirr<#ts8)cmJcC<$JcC<$rVrks"8i,uq#:9np[S4es82cns8DVAs+13$s+14J
...
def
(note it occurs twice)

note the new width and height from the ps file and search/replace that number 
throughout festival-form.pl with the new one
enter the imag height or width in scripts as required - you may need a fiddle
factor to make it look right.
change any other text as required (esp the dates of the festival!)

Jonathan
