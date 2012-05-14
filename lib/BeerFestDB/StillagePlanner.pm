#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010-2012 Tim F. Rayner
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id$

package BeerFestDB::StillagePlanner;

use 5.008;

use strict; 
use warnings;

=begin comment

 DESIGN IDEAS

Some starting ideas: generate a series of cask objects, each of which
will be able to calculate a score representing how out-of-place it is,
based on a series of rules to be defined. Some use cases which have
turned up:

1. Alphabetical order (obviously). Maybe rank casks and create a score
based on the current position compared to the ideal position?

2. Location relative to other casks of the same beer. This will depend
on cask type (firkins tend to be in rows on the bottom; kils can be
either back-feeders on top or arranged one-up(front), two-down for
pullthrough).

3. We need to allow for the presence of gaps in the stillage;
backfeeders must not straddle gaps and generally such straddling by
a given beer is to be avoided.

4. Different stillages will want different styles (e.g. South bar
firkins on top of stillage for pull-through rather than using
backfeeders).

5. Mixed sets of kils and firkins within a given beer will be tricky.

6. Some beer will be left on the deck. The penalty for this happening
is less for the higher cask numbers (e.g. cask 6 of a given beer will
almost always be left out if there's no room; casks 1 and 2 should
never be left out). Very low penalty for sale-or-return beers. This
means that the cask objects need to be created with appropriate
annotation and numbering (the latter won't come from the database
until after the casks arrive, at which point we might want to rerun
the planner).

7. Every beer should have at least one cask in a position ready to
serve; preferably two. This probably biases some of the weightings for
the first two casks. Ideally there would be a defined strategy to cask
progression during sales (see point 2).

Once the casks have been created, we'll probably want to generate a
starting layout either randomly or using some other approach. Then
there could be an iterative and suspiciously recursive process where
the most out-of-place cask is moved to a better spot (maybe a quick
search of its surroundings?), the displaced cask similarly moved, and
so on until things stabilise (n.b. there's no guarantee against cycles
in this, we'll want to check for that by recording all the cask
movements within a given displacement run). Repeat until the total
out-of-placedness across all casks converges (and there's no guarantee
of convergence either; possibly record all past states of the stillage
as a hash to check for larger-scale cycles?).

=end comment

=cut

use Moose;

use Carp;

use Data::Dumper;

our $VERSION = '0.01';



1;
__END__

=head1 NAME

BeerFestDB::StillagePlanner - Automated placement of casks on stillage

=head1 SYNOPSIS

 use BeerFestDB::StillagePlanner;
 # back away carefully

=head1 DESCRIPTION

A hilariously underpowered attempt to create a configurable algorithm
that places casks in some semblance of order along a stillage. Watch
and be amazed at the convolutions! Gibber at the hubris!

=head2 EXPORT

None by default. Not been a fan of McEwan's for many many years now.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut
