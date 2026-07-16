#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010-2026 Tim F. Rayner
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

use List::Util qw(first);

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
        long_description   => 'long_description',
        comment          => 'comment',
        nominal_abv      => 'nominal_abv',
        product_style_id => 'product_style_id',
        product_category_id => 'product_category_id',
        category_name    => {
            product_category_id => 'description',
        },
        is_vegan         => 'is_vegan',
        allergens_present => undef, # See viewhash_from_model below.
        allergens_absent  => undef, # See viewhash_from_model below.
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
        $c->res->redirect( $c->uri_for('list_by_company', $company_id, $category_id) );
    }

    # This is just a product listing at this stage; one row per
    # product (per supplier). If festival_id is supplied then the list
    # is filtered based on which products are at a given
    # festival. Note that this listing is therefore swinging between
    # the virtual (no $festival_id) and the concrete ($festival_id,
    # linking via cask and gyle). At some point it may be wiser to
    # split this method, e.g. building on the FestivalProduct class instead.

    my ( $rs, $festival );
    my $cond = defined $category_id ? { product_category_id => $category_id }
                                    : {};
    my $prefetch = defined $category_id ? [ 'company_id' ]
                                        : [ 'company_id', 'product_category_id' ];
    if ( defined $festival_id ) {
        $festival = $c->model( 'DB::Festival' )->find({festival_id => $festival_id});
        unless ( $festival ) {
            $c->stash->{error} = 'Festival not found.';
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $festival->search_related('festival_products')
                       ->search_related('product_id', $cond, { prefetch => $prefetch });
    }
    else {
        $rs = $c->model( 'DB::Product' )->search_rs($cond, { prefetch => $prefetch });
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
    my ( $self, $c, $company_id, $category_id ) = @_;

    my $rs;
    if ( defined $company_id ) {
        my %query = ( company_id => $company_id );
        if ( defined $category_id ) {
            $query{ 'me.product_category_id' } = $category_id;
        }
        $rs = $c->model( 'DB::Product' )->search_rs( \%query,
            { prefetch => [ 'product_category_id' ] });
    }
    else {
        $c->stash->{error} = 'Company ID not provided.';
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();
    }

    $self->generate_json_and_detach( $c, $rs );
}

=head2 list_by_festival

=cut

sub list_by_festival : Local {

    my ( $self, $c, $festival_id, $category_id ) = @_;

    my $rs;
    if ( defined $festival_id ) {
        my %query = ( 'festival_products.festival_id' => $festival_id );
        if ( defined $category_id ) {
            $query{ 'me.product_category_id' } = $category_id;
        }
        $rs = $c->model( 'DB::Product' )->search_rs( \%query,
            {
                join => 'festival_products',
                prefetch => [ 'company_id', 'product_category_id' ],
            } );
    }
    else {
        $c->stash->{error} = 'Festival ID not provided.';
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();
    }

    $self->generate_json_and_detach( $c, $rs );
}

=head2 list_by_order_batch

=cut

sub list_by_order_batch : Local {

    my ( $self, $c, $batch_id, $category_id ) = @_;

    # A little kludgey, might be nicer to do this as a JSON query, but
    # we're limited by the extJS JSONStore.load() method here.
    if ( my $company_id = $c->req()->params()->{ company_id } ) {
        $c->res->redirect( $c->uri_for('list_by_company', $company_id, $category_id) );
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
                    ->search_related('product_id',
                                     defined $category_id
                                         ? { product_category_id => $category_id } : {},
                                     {
                                        prefetch => defined $category_id
                                            ? [ 'company_id' ]
                                            : [ 'company_id', 'product_category_id' ],
                                     }
    );
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

=head2 build_database_object

=cut

sub build_database_object : Private {

    my ( $self, $rec, $c, @other ) = @_;

    # Our regular build_database_object method doesn't handle many-to-many.
    my $allergens_present = delete $rec->{'allergens_present'} || '';
    my $allergens_absent  = delete $rec->{'allergens_absent'} || '';

    # Detect a category change before the update is applied.
    my $old_category_id;
    if ( defined $rec->{product_id} ) {
        my $existing = $c->model('DB::Product')->find({ product_id => $rec->{product_id} });
        if ( $existing && defined $rec->{product_category_id}
                       && $existing->product_category_id != $rec->{product_category_id} ) {
            $old_category_id = $existing->product_category_id;
        }
    }

    my $obj = $self->next::method( $rec, $c, @other );

    # Check that all the wanted allergens are set appropriately.
    if ( defined $obj && $obj->result_source()->source_name eq 'Product' ) {
       
        my $rs = $c->model( 'DB::ProductAllergen' );

        # Note here that we set present=1 for allergens marked as both
        # present and absent. This seems best from a safety perspective.
        my @present = split /,/, $allergens_present;
        my %selected = map { $_ => 1 } @present;
        my @absent = grep { !$selected{$_} } split /,/, $allergens_absent;
        foreach my $allergen_id (@present) {
            my $pa = $rs->find_or_create({ product_id => $obj->product_id(),
                                           product_allergen_type_id => $allergen_id });
            $pa->update({present => 1 });
        }
        foreach my $allergen_id (@absent) {
            my $pa = $rs->find_or_create({ product_id => $obj->product_id(),
                                           product_allergen_type_id => $allergen_id });
            $pa->update({present => 0 });
        }

        # Delete unwanted existing allergens.
        foreach my $existing ($obj->product_allergens) {
            if ( ! first { $existing->get_column('product_allergen_type_id') == $_ } (@present, @absent) ) {
                $existing->delete;
            }
        }

        # If the product category changed, reconcile any ProductCharacteristics
        # whose type no longer belongs to the new category.
        if ( defined $old_category_id ) {
            $self->_reconcile_characteristics_after_category_change(
                $c, $obj, $rec->{product_category_id} );
        }
    }

    return $obj;
}

=head2 _reconcile_characteristics_after_category_change

Called when a Product's product_category_id is changed. Iterates over
all attached ProductCharacteristic rows; for each one whose
ProductCharacteristicType belongs to the old category:

=over 4

=item * If a ProductCharacteristicType with the same description exists in
the new category, updates the characteristic to use that type.

=item * Otherwise, deletes the characteristic.

=back

=cut

sub _reconcile_characteristics_after_category_change : Private {

    my ( $self, $c, $obj, $new_category_id ) = @_;

    my $pct_rs = $c->model('DB::ProductCharacteristicType');

    foreach my $char ( $obj->product_characteristics ) {
        my $type = $char->product_characteristic_type_id;
        next if $type->get_column('product_category_id') == $new_category_id;

        # Type belongs to the old category. Try to find a replacement
        # in the new category with the same description.
        my $replacement = $pct_rs->find({
            product_category_id => $new_category_id,
            description         => $type->description,
        });

        if ( $replacement ) {
            # Check whether a characteristic for this product with the
            # replacement type already exists (avoid PK collision).
            my $existing = $c->model('DB::ProductCharacteristic')->find({
                product_id                    => $obj->product_id,
                product_characteristic_type_id => $replacement->product_characteristic_type_id,
            });
            if ( $existing ) {
                # Replacement already exists; just remove the mismatched one.
                $char->delete;
            }
            else {
                $char->update({
                    product_characteristic_type_id =>
                        $replacement->product_characteristic_type_id,
                });
            }
        }
        else {
            $char->delete;
        }
    }

    return;
}

=head2 viewhash_from_model

=cut

sub viewhash_from_model : Private {

    my ( $self, $view_key, $dbrow, $lookup ) = @_;

    my $rc;
    if ( $view_key eq 'allergens_present' ) {
        $rc = join(',', map { $_->get_column('product_allergen_type_id') } $dbrow->allergens_present);
    }
    elsif ( $view_key eq 'allergens_absent' ) {
        $rc = join(',', map { $_->get_column('product_allergen_type_id') } $dbrow->allergens_absent);
    }
    else {
        $rc = $self->next::method( $view_key, $dbrow, $lookup );
    }

    return $rc;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
