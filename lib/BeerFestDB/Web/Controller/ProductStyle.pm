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

package BeerFestDB::Web::Controller::ProductStyle;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::GenericGrid'; }

=head1 NAME

BeerFestDB::Web::Controller::ProductStyle - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        product_style_id      => 'product_style_id',
        product_category_id   => 'product_category_id',
        description           => 'description',
    });

    $self->model_name('DB::ProductStyle');
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    if ( my $category_id = $c->req()->params()->{ product_category_id } ) {
        $c->res->redirect( $c->uri_for('list_by_category', $category_id) );
    } else {
        $self->SUPER::list($c);
    }
}

=head2 list_by_category

=cut

sub list_by_category : Local {

    my ( $self, $c, $id ) = @_;

    my $rs = $c->model( $self->model_name() )->search({ product_category_id => $id });

    $self->generate_json_and_detach( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $category_id ) = @_;

    if ( defined $category_id ) {
        my $category = $c->model( 'DB::ProductCategory' )->find($category_id);
        unless ( $category ) {
            $c->flash->{error} = "Error: Product Category not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $c->stash->{category} = $category;
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
