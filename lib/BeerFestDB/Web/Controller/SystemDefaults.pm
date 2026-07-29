#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2017 Tim F. Rayner
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

package BeerFestDB::Web::Controller::SystemDefaults;
use Moose;
use namespace::autoclean;

BEGIN { extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::SystemDefaults - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        system_default_id    => 'system_default_id',
        description          => 'description',
    });

    $self->model_name('DB::SystemDefaults');
}

=head2 load_form

=cut

sub load_form : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( $self->model_name() );

    $self->form_json_and_detach( $c, $rs, 'system_default_id' );
}

=head2 view

=cut

sub view : Local {

    my ( $self, $c ) = @_;

    my $object = $c->model( $self->model_name() )->find(1);

    unless ( $object ) {
        $c->flash->{error} = "Error: SystemDefault not found.";
        $c->res->redirect( $c->uri_for('/systemdefaults/grid') );
        $c->detach();        
    }

    $c->stash->{object} = $object;

    return;
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( $self->model_name() );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    $self->flash->{error} = "Error: SystemDefaults cannot be deleted.";

    $self->res->redirect( $c->uri_for('/systemdefaults/view') );
}


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
