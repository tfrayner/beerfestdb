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

package BeerFestDB::Web::Controller::ProductCharacteristic;
use Moose;
use namespace::autoclean;

BEGIN { extends 'BeerFestDB::Web::GenericGrid'; }

=head1 NAME

BeerFestDB::Web::Controller::ProductCharacteristic - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        product_id                     => 'product_id',
        product_characteristic_type_id => 'product_characteristic_type_id',
        value                          => 'value',
    });

    $self->model_name('DB::ProductCharacteristic');
}

=head2 load_form

=cut

sub load_form : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( $self->model_name() );

    $self->form_json_and_detach( $c, $rs, 'product_characteristic_id' );
}

=head2 view

=cut

sub view : Local {

    my ( $self, $c, $id ) = @_;

    my $object = $c->model( $self->model_name() )->find($id);

    unless ( $object ) {
        $c->flash->{error} = "Error: ProductCharacteristic not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }

    $c->stash->{object} = $object;

    return;
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    if ( my $product_id = $c->req()->params()->{ product_id } ) {
        $c->res->redirect( $c->uri_for('list_by_product', $product_id) );
    } else {
        $self->SUPER::list($c);
    }
}

=head2 list_by_product

=cut

sub list_by_product : Local {

    my ( $self, $c, $product_id ) = @_;

    my $rs = $c->model( $self->model_name() )->search({ product_id => $product_id });

    $self->generate_json_and_detach( $c, $rs );
}

=head2 build_database_object

=cut

sub build_database_object {

    my ( $self, $rec, $c, @other ) = @_;

    # Confirm that the ProductCharacteristicType is valid for the product's Category.
    my $type     = $c->model("DB::ProductCharacteristicType")->find($rec->{product_characteristic_type_id});
    my $product  = $c->model("DB::Product")->find($rec->{product_id});

    if ( $type->product_category_id != $product->product_category_id ) {
        $self->raise_exception($c, "Product characteristic type is not valid for the product's category.\n");
    }

    return $self->next::method( $rec, $c, @other );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
