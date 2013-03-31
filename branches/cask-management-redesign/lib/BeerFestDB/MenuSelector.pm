#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010 Tim F. Rayner
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

package BeerFestDB::MenuSelector;
use Moose::Role;
use namespace::autoclean;
use Scalar::Util qw(looks_like_number);

requires 'database';

=head1 NAME

BeerFestDB::MenuSelector - Command-line menus.

=head1 DESCRIPTION

This is a Role class providing utility functions used to allow the
user to select database objects (e.g., the Festival of interest) from
within command-line scripts.

=head1 METHODS

=head2 select_festival

=cut

sub select_festival {

    my ( $self ) = @_;

    # Just retrieve the casks for the festival in question. We need an
    # interactive menu here.
    my @festivals = $self->database->resultset('Festival')->all();

    my $wanted;

    SELECT:
    {
        warn("Please select the beer festival of interest:\n\n");
        foreach my $n ( 1..@festivals ) {
            my $fest = $festivals[$n-1];
            warn(sprintf("  %d: %d %s\n", $n, $fest->year, $fest->name));
        }
        warn("\n");
        chomp(my $select = <STDIN>);
        redo SELECT unless ( looks_like_number( $select )
                                 && ($wanted = $festivals[ $select-1 ]) );
    }

    return $wanted;
}

=head2 select_order_batch

=cut

sub select_order_batch {

    my ( $self, $festival ) = @_;

    if ( ! $festival ) {
        $festival = $self->select_festival();
    }

    # Just retrieve the casks for the festival in question. We need an
    # interactive menu here.
    my @batches = $festival->order_batches();

    my $wanted;

    SELECT:
    {
        warn("Please select the order batch:\n\n");
        foreach my $n ( 1..@batches ) {
            my $batch = $batches[$n-1];
            warn(sprintf("  %d: %s %s\n", $n, $batch->description, $batch->order_date || q{}));
        }
        warn("\n");
        chomp(my $select = <STDIN>);
        redo SELECT unless ( looks_like_number( $select )
                                 && ($wanted = $batches[ $select-1 ]) );
    }

    return $wanted;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

no Moose::Role;

1;
