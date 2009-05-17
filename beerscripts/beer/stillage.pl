#!/usr/bin/perl
# items.pl

use Tk;
use strict;

use subs qw/items_drag items_drag_beer items_enter items_leave items_mark
	    items_click1 items_release1 items_stroke items_under_area save/;
use vars qw/$TOP/;

$TOP=MainWindow->new();

my $factor = 90/12;
my $bayheight = 16 * $factor;
my $baywidth = 66 * $factor;
my $margin = 5 * $factor;

my $bays = 41;
my $maxid = 1;

# translate to SE row names
my @rownames = qw(ub uf lb lm lf ff);

my @casks;
my $datafile = shift || "casklist";
open(BEERS, $datafile) or die "can't find $datafile\n";
while(<BEERS>) {
	chop;
	my ($id, $size, $brewery, $beer, $abv, $supplier, undef, undef, undef, $facing, $xs, $ys) = split (/:/);
	$size ||= 99; # bogus
	push @casks, [ $id, $size, $brewery, $beer, $abv, $supplier, undef, undef, undef, $facing, $xs, $ys ];
	$maxid = $id if $id > $maxid;
}

items();
MainLoop;

my $dragging_item = 0; # workaround to stop Canvas bindings happening after item bindings

sub items {

    # Create a top-level window containing a canvas that displays the various
    # item types and allows them to be selected and moved.

    my $c = $TOP->Scrolled(qw/Canvas -width 50c -height 30c -relief sunken
			   -borderwidth 2 -scrollbars se -scrollregion/ =>
			   [qw/0c 0c/, $bays * $baywidth, qw/30c/]);
    $c->pack(qw/-expand yes -fill both/);

    my %iinfo = ();		# item information hash
    $iinfo{areaX1} = 0;
    $iinfo{areaY1} = 0;
    $iinfo{areaX2} = 0;
    $iinfo{areaY2} = 0;
    
	# Display a 3x3 rectangular grid (800.016 or greater).
	$c->createGrid(0, 0, $baywidth, $bayheight, qw/-width 2 -lines 1/);
	#$c->createGrid(qw/0c  0c 5c  4c -lines 1 -dash ./);
	$c->createGrid(qw/0c  0c 10m 8m -width 1/);

    my $font1 = '-*-Helvetica-Medium-R-Normal--*-120-*-*-*-*-*-*';
    my $font2 = '-*-Helvetica-Bold-R-Normal--*-240-*-*-*-*-*-*';

	# bay labels
	for (my $bay = 1; $bay<=$bays; $bay++) {
		$c->createText($baywidth*($bay-1)+10, $bayheight*5.2, "-text", $bay);
	}


    #$c->createText(qw/15c 8.2c -text Ovals -anchor n/);
	my ($xd, $yd) = (0,5*$bayheight);
	my %size = ( 
		9 => 12,
		11 => 13,
		18 => 15,
		22 => 16
	);
	foreach (reverse @casks) {
		my ($id, $size, $brewery, $beer, $abv, $supplier, undef, undef, undef, $facing, $xs, $ys) = @$_;
		my $label = "$id\n$brewery\n$beer";
		my $diam = $size{$size} || 20;
		$diam *= $factor;
		my $tag = "cask$id";
                my $btag = "beer$brewery:$beer";
                $btag =~ s/[^\w:]//g;
		my $x = (defined $xs && $xs ne '') ? $xs : $xd;
		my $y = (defined $ys && $ys ne '') ? $ys : $yd;
    $c->createOval($x, $y, $x+$diam, $y+$diam, -fill => 'orange',
	           qw/-width 2 -tags/, "item $tag $btag", qw/-outline yellow -activeoutline green/);
    $c->createText($x+$diam/2, $y+$diam/2, qw/-text/, $label, "-tags", "item label $tag $btag", qw/-anchor center -justify center -fill black/);
	}

	# bindings
    $c->bind('item', '<1>' =>
        sub {items_click1 shift, $Tk::event->x, $Tk::event->y, \%iinfo});
    $c->bind('item', '<B1-Motion>' =>
        sub {items_drag shift, $Tk::event->x, $Tk::event->y, \%iinfo});
    $c->bind('item', '<Control-B1-Motion>' =>
        sub {items_drag_beer shift, $Tk::event->x, $Tk::event->y, \%iinfo});
    $c->bind('item', '<B1-ButtonRelease>' =>
        sub {items_release1 shift, $Tk::event->x, $Tk::event->y, \%iinfo});
    $c->CanvasBind('<1>' => 
         sub {items_mark shift, $Tk::event->x, $Tk::event->y, \%iinfo});
    $c->CanvasBind('<B1-Motion>' =>
         sub {items_stroke shift, $Tk::event->x, $Tk::event->y, \%iinfo});
    $c->CanvasBind('<B1-ButtonRelease>' =>
         sub {items_under_area shift, \%iinfo});
    $c->CanvasBind('<2>' => 
        sub {shift->scan('mark', $Tk::event->x, $Tk::event->y)});
    $c->CanvasBind('<B2-Motion>' =>
         sub {shift->scan('dragto', $Tk::event->x, $Tk::event->y, 4)});
    $c->CanvasBind('<Any-Enter>' => sub {$_[0]->CanvasFocus});
    $c->CanvasBind('<Any-9>' => sub {create_spacer (shift, 9, $size{9}*$factor, "(space)")});
    $c->CanvasBind('<Any-8>' => sub {create_spacer (shift, 18, $size{18}*$factor, "(space)")});
    $c->CanvasBind('<Any-c>' => sub {create_spacer (shift, 18, $size{18}*$factor, "Cooler")});
    $c->CanvasBind('<Control-s>' => sub {save shift});
    $c->CanvasBind('<Control-w>' => sub {exit});
    $c->CanvasBind('<Control-a>' => sub {arrange_bays(shift)});
    $c->CanvasBind('<Control-p>' => sub {shift->postscript(qw/-file out.ps/)});

} # end items

# event handlers

sub create_spacer {
	my ($c, $size, $diam, $breweryfield) = @_;
	my $x = $c->canvasx($Tk::event->x) - $diam/2;
	my $y = $c->canvasy($Tk::event->y) - $diam/2;
	my $id = ++$maxid;
	my $tag = "cask$id";
	print "adding $breweryfield $size id $id at $x:$y\n";
	# some code duplication with above foreach @casks
	$c->createOval($x, $y, $x+$diam, $y+$diam, -fill => 'orange',
	           qw/-width 2 -tags/, "item $tag", qw/-outline yellow -activeoutline green/);
    	$c->createText($x+$diam/2, $y+$diam/2, qw/-text/, $breweryfield, "-tags", "item label $tag", qw/-anchor center -justify center -fill black/);
	push @casks, [ $id, $size, $breweryfield, undef, undef, undef, undef, undef, undef, undef $x, $y ];
}

sub save {
	my ($c) = @_;

	open(SAVE, ">$datafile") or die "can't write to $datafile:$!\n";
	foreach (@casks) {
		my ($id, $size, $brewery, $beer, $abv, $supplier, $cbay, $crow, $cpos, $facing, $xs, $ys) = @$_;

		# find screen coords of cask
		my $c_id = $c->find('withtag', "!label&&cask$id");
		($xs, $ys) = ($c->coords($c_id));
		print SAVE join(':', $id, $size, $brewery, $beer, $abv, $supplier, $cbay, $crow, $cpos, $facing, $xs, $ys);
		print SAVE "\n";
	}
	close SAVE;
}

sub items_click1 {

    my($c, $x, $y, $iinfo) = @_;

	# if this cask is not selected, cancel selection and select it instead
	my @tags = $c->gettags('current'); 
	if (! defined($tags[0]) or ! grep $_ eq 'selected', @tags) {
		$c->itemconfigure(qw/selected&&!label -fill orange/);
		$c->dtag('selected');
		select_cask($c, $c->find(qw/withtag current/));
		#$c->addtag('selected', 'withtag', 'current');
		#$c->itemconfigure(qw/selected -fill SteelBlue/);
	}

    $iinfo->{lastX} = $c->canvasx($x);
    $iinfo->{lastY} = $c->canvasy($y);

	$dragging_item = 1;
} # end items_click1

sub items_drag_beer {

    my($c, $x, $y, $iinfo) = @_;

    $x = $c->canvasx($x);
    $y = $c->canvasy($y);
    my ($tag) = grep /^beer/, $c->gettags('current');
    $c->move($tag, $x-$iinfo->{lastX}, $y-$iinfo->{lastY});
    $iinfo->{lastX} = $x;
    $iinfo->{lastY} = $y;

} # end items_drag

sub items_drag {

    my($c, $x, $y, $iinfo) = @_;

    $x = $c->canvasx($x);
    $y = $c->canvasy($y);
    #$c->move('current', $x-$iinfo->{lastX}, $y-$iinfo->{lastY});
    $c->move('selected', $x-$iinfo->{lastX}, $y-$iinfo->{lastY});
    $iinfo->{lastX} = $x;
    $iinfo->{lastY} = $y;

} # end items_drag

sub items_release1 {
	$dragging_item = 1;
}

sub items_mark {

    my($c, $x, $y, $iinfo) = @_;

	return if $dragging_item;

	# cancel current selection
	$c->itemconfigure(qw/selected&&!label -fill orange/);
	$c->dtag('selected');

    $iinfo->{areaX1} = $c->canvasx($x);
    $iinfo->{areaY1} = $c->canvasy($y);
    $iinfo->{areaX2} = $c->canvasx($x);
    $iinfo->{areaY2} = $c->canvasy($y);

} # end items_mark

sub items_stroke {

    my($c, $x, $y, $iinfo) = @_;

	return if $dragging_item;

    $x = $c->canvasx($x);
    $y = $c->canvasy($y);
    if (($iinfo->{areaX1} != $x) and ($iinfo->{areaY1} != $y)) {
	$c->delete('area');
	$c->addtag('area', 'withtag', $c->create('rectangle',
	    $iinfo->{areaX1}, $iinfo->{areaY1}, $x, $y, -outline => 'black'));
	$iinfo->{areaX2} = $x;
	$iinfo->{areaY2} = $y;
    }

} # end items_stroke

sub items_under_area {

    my($c, $iinfo) = @_;

	if ($dragging_item) {
		$dragging_item = 0;
		return;
	}

    my $area = $c->find('withtag', 'area');
    my @items  = ();
    my $i;
    my @casks = $c->find('overlapping', $iinfo->{areaX1},
            $iinfo->{areaY1}, $iinfo->{areaX2}, $iinfo->{areaY2});
	select_cask($c, @casks);
    #$c->addtag('selected', 'overlapping', $iinfo->{areaX1},
    #        $iinfo->{areaY1}, $iinfo->{areaX2}, $iinfo->{areaY2});
	#$c->itemconfigure(qw/selected -fill SteelBlue/);

	$c->delete('area');

} # end items_under_area

sub select_cask {
	my ($c, @items) = @_;

    foreach my $i (@items) {
		my $casktag = (grep (/^cask/, $c->gettags($i)))[0];
		next unless defined $casktag;
		$c->addtag('selected', 'withtag', $casktag);
		$c->itemconfigure(qw/selected&&!label -fill SteelBlue/);
	}
}

sub arrange_bays {
	my ($c) = @_;
	# calc coordinates of each bay

	for (my $bay = 1; $bay<=$bays; $bay++) {
	 for (my $row = 0; $row<=4; $row++) {
		my $x1=($bay-1)*$baywidth;
		my $x2=$bay*$baywidth;
		my $y1=$row*$bayheight;
		my $y2=($row+1)*$bayheight;
		my @items = $c->find('overlapping', $x1+$margin, $y1+$margin, $x2-$margin, $y2-$margin);
		arrange_row($c, $bay, $row, [$x1, $y1, $x2, $y2], @items);
	    # if casks don't  fit in bay they get shunted to the next
	 }
	}

        # mark items on floor
	my @items = $c->find('overlapping', 0, 5*$bayheight+$margin, $bays*$baywidth, 99*$bayheight);
        foreach my $canvasid (@items) {
                my $bay = 1;
		my @tags = $c->gettags($canvasid);
		next if (grep /^label/, @tags);
		my $casktag = (grep /^cask/, @tags)[0];
		(my $caskid = $casktag) =~ s/^cask//;
		my $btag = (grep /^beer/, @tags)[0];
                (my $brewery) = $btag =~ /^beer(.*):/;

                # find the first cask from this brewery and use that bay
		for (my $i=0; $i<=$#casks; $i++) {
                  my $abrewery = $casks[$i][2];
                  $abrewery =~ s/[^\w:]//g; # match tagging strategy
                  if ($abrewery eq $brewery && $casks[$i][7] ne $rownames[5]) {
                    $bay = $casks[$i][6];
                    last;
                  }
                }
                $bay ||=16; # in case brewery not found on stillage (possible bug here)

		# find the cask with this ID and save the position
		for (my $i=0; $i<=$#casks; $i++) {
			next unless $casks[$i][0] == $caskid;
			@{$casks[$i]}[6,7,8] = ($bay, $rownames[5], 5);
                        last;
		}
        }
}

sub arrange_row {
	my ($c, $bay, $row, $baycoords, @items) = @_;

	my (@items2);
	# get list 
    #my @items = $c->find('withtag', 'selected&&!label');

	# get cask ids from tags
    foreach my $canvasid (reverse @items) {
		my @tags = $c->gettags($canvasid);
		next if (grep /^label/, @tags);
		my $casktag = (grep /^cask/, @tags)[0];
		(my $caskid = $casktag) =~ s/^cask//;
		my @coords = $c->coords($canvasid);
		push @items2, [$coords[0], $caskid, $canvasid, @coords];
	}

	my $pos = 0;
	my $cursor = 0;
	my $floor = 0;
	# sort by x coords
	foreach my $a (sort {$a->[0] <=> $b->[0]} @items2) {
		my ($coord, $caskid, $canvasid, @coords) = @{$a};
		# move first cask to end of bay
		if ($pos == 0) { 
			$cursor = $baycoords->[0];
			$floor = $baycoords->[3];
		}
		# move cask to cursor
		my $movex = $cursor - $coords[0];
		my $movey = $floor - $coords[3];
		$c->move("cask$caskid", $movex, $movey);
		# add width to cursor
		$cursor += $coords[2]-$coords[0];

		# find the cask with this ID and save the bay/row/position
		for (my $i=0; $i<=$#casks; $i++) {
			next unless $casks[$i][0] == $caskid;
			@{$casks[$i]}[6,7,8] = ($bay, $rownames[$row], $pos);
                        last;
		}

	} continue {
		$pos++;
	}
	return;
}
