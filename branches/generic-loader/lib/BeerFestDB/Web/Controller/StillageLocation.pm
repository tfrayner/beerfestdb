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

package BeerFestDB::Web::Controller::StillageLocation;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::StillageLocation - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        stillage_location_id => 'stillage_location_id',
        festival_id          => 'festival_id',
        description          => 'description',
    });
}

sub list : Local {

    my ( $self, $c, $festival_id ) = @_;

    my ( $rs, $festival );
    if ( defined $festival_id ) {
        $festival = $c->model( 'DB::Festival' )->find({festival_id => $festival_id});
        unless ( $festival ) {
            $c->stash->{error} = qq{Festival ID "$festival_id" not found.};
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $festival->stillage_locations()
    }
    else {
        die('Error: festival_id not defined.');
    }

    $self->generate_json_and_detach( $c, $rs );
}

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::StillageLocation');

    $self->write_to_resultset( $c, $rs );
}

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::StillageLocation');

    $self->delete_from_resultset( $c, $rs );
}

sub grid : Local {

    my ( $self, $c, $stillage_id ) = @_;

    if ( defined $stillage_id ) {
        my $stillage = $c->model('DB::StillageLocation')->find($stillage_id);
        unless ( $stillage ) {
            $c->flash->{error} = "Error: Stillage not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{stillage} = $stillage;
    }

    return;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
