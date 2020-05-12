#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2020 Tim F. Rayner
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

package TestGenericGrid;

use 5.008;

use strict; 
use warnings;

use Carp;

use Test::More;

require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(generic_grid_tests);

sub generic_grid_tests {

    my ( $action, $class, $ua, $skip_grid ) = @_;

    # Using the fixtures set up in TestFestivalDB:
    $ua->get_ok("/$action/list",
                "$class list should succeed" );

    # Often not implemented as unnecessary.
    if ( not $skip_grid ) {
        $ua->get_ok("/$action/grid",
                    "$class grid should succeed" );
    }

    # The following need JSON payloads and (in the case of delete) user confirmation.
    #$ua->get_ok("/$action/submit", "$class submit should succeed" );
    #$ua->get_ok("/$action/delete", "$class delete should succeed" );

}
