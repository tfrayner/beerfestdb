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

package BeerFestDB::Web::Controller::Product;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

use Storable qw(dclone);

=head1 NAME

BeerFestDB::Web::Controller::Product - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        product_id       => 'product_id',
        company_id       => 'company_id',
        company_name     => {
            company_id     => 'name',
        },
        name             => 'name',
        description      => 'description',
        comment          => 'comment',
        nominal_abv      => 'nominal_abv',
        product_style_id => 'product_style_id',
        product_category_id => 'product_category_id',
        category_name    => {
            product_category_id => 'description',
        },
    });
}

=head2 load_form

=cut

sub load_form : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::Product');

    $self->form_json_and_detach( $c, $rs, 'product_id' );
}

=head2 index

=cut

sub index :Path :Args(0) {

    # Listing of product types linking to grid views for each.
    my ( $self, $c ) = @_;

    my @categories = $c->model('DB::ProductCategory')->all(); 

    $c->stash->{categories} = \@categories;
}

=head2 view

=cut

sub view : Local {

    my ( $self, $c, $id ) = @_;

    my $object = $c->model('DB::Product')->find($id);

    unless ( $object ) {
        $c->flash->{error} = "Error: Product not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }

    $c->stash->{object} = $object;

    return;
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c, $category_id, $festival_id ) = @_;

    # A little kludgey, might be nicer to do this as a JSON query, but
    # we're limited by the extJS JSONStore.load() method here.
    if ( my $company_id = $c->req()->params()->{ company_id } ) {
        $c->res->redirect( $c->uri_for('list_by_company', $company_id) );
    }

    # This is just a product listing at this stage; one row per
    # product (per supplier). If festival_id is supplied then the list
    # is filtered based on which products are at a given
    # festival. Note that this listing is therefore swinging between
    # the virtual (no $festival_id) and the concrete ($festival_id,
    # linking via cask and gyle). At some point it may be wiser to
    # split this method, e.g. building on the FestivalProduct class instead.

    my ( $rs, $festival );
    my $cond = defined $category_id ? { product_category_id => $category_id } : {};
    if ( defined $festival_id ) {
        $festival = $c->model( 'DB::Festival' )->find({festival_id => $festival_id});
        unless ( $festival ) {
            $c->stash->{error} = 'Festival not found.';
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $festival->search_related('festival_products')
                       ->search_related('product_id', $cond);
    }
    else {
        $rs = $c->model( 'DB::Product' )->search_rs($cond);
    }
    
    $self->generate_json_and_detach( $c, $rs );
}

=head2 list_by_company

=cut

sub list_by_company : Local {

    # Sketched-out method to retrieve all products produced by a given
    # company. It seems likely that this will not be immediately
    # useful; instead we'll probably just filter on our productStore
    # in the javascript. This has the benefit of pre-filtering by
    # category in the list method.
    my ( $self, $c, $company_id ) = @_;

    my $rs;
    if ( defined $company_id ) {
        $rs = $c->model( 'DB::Product' )->search_rs( { company_id => $company_id } );
    }
    else {
        $c->stash->{error} = 'OrderBatch ID not provided.';
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();
    }

    $self->generate_json_and_detach( $c, $rs );
}

=head2 list_by_order_batch

=cut

sub list_by_order_batch : Local {

    my ( $self, $c, $batch_id ) = @_;

    # A little kludgey, might be nicer to do this as a JSON query, but
    # we're limited by the extJS JSONStore.load() method here.
    if ( my $company_id = $c->req()->params()->{ company_id } ) {
        $c->res->redirect( $c->uri_for('list_by_company', $company_id) );
    }

    my $rs;
    if ( defined $batch_id ) {
        my $batch = $c->model( 'DB::OrderBatch' )->find($batch_id);
        unless ( $batch ) {
            $c->stash->{error} = 'Order Batch not found.';
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $batch->search_related('product_orders')
                    ->search_related('product_id');
    }
    else {
        $c->stash->{error} = 'OrderBatch ID not provided.';
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();
    }

    $self->generate_json_and_detach( $c, $rs );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Product' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Product' );

    $self->delete_from_resultset( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $category_id, $festival_id ) = @_;

    if ( defined $festival_id ) {
        my $festival = $c->model('DB::Festival')->find($festival_id);
        unless ( $festival ) {
            $c->flash->{error} = "Error: Festival not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{festival} = $festival;
    }

    my $category = $c->model('DB::ProductCategory')->find($category_id);
    unless ( $category ) {
        $c->flash->{error} = "Error: Product category not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }
    $c->stash->{category} = $category;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
