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

package BeerFestDB::Web::Controller::CompanyRegion;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::GenericGrid'; }

=head1 NAME

BeerFestDB::Web::Controller::CompanyRegion - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        company_region_id  => 'company_region_id',
        description        => 'description',
    });

    $self->model_name('DB::CompanyRegion');
}

=head2 load_form

=cut

sub load_form : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( $self->model_name() );

    $self->form_json_and_detach( $c, $rs, 'company_region_id' );
}

=head2 view

=cut

sub view : Local {

    my ( $self, $c, $id ) = @_;

    my $object = $c->model( $self->model_name() )->find($id);

    unless ( $object ) {
        $c->flash->{error} = "Error: CompanyRegion not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }

    $c->stash->{object} = $object;

    return;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
