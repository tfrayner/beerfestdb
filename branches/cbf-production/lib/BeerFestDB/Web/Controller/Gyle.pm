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

package BeerFestDB::Web::Controller::Gyle;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::Gyle - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        gyle_id           => 'gyle_id',
        company_id        => 'company_id',
        festival_product_id => 'festival_product_id',
        abv               => 'abv',
        comment           => 'comment',
        ext_reference     => 'external_reference',
        int_reference     => 'internal_reference',
    });
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched BeerFestDB::Web::Controller::Gyle in Gyle.');
}

=head2 list_by_festival_product

=cut

sub list_by_festival_product : Local {

    my ( $self, $c, $id ) = @_;

    my $rs = $c->model( 'DB::Gyle' )->search({ festival_product_id => $id });

    $self->generate_json_and_detach( $c, $rs );
}

=head2 list_by_festival

=cut

sub list_by_festival : Local {

    my ( $self, $c, $id ) = @_;

    my $rs = $c->model( 'DB::Gyle' )->search(
        { 'festival_product_id.festival_id' => $id },
        { join => 'festival_product_id' },
    );

    $self->generate_json_and_detach( $c, $rs );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Gyle' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Gyle' );

    $self->delete_from_resultset( $c, $rs );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
