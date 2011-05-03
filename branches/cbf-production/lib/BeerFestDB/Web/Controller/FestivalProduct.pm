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

package BeerFestDB::Web::Controller::FestivalProduct;
use Moose;
use namespace::autoclean;

use List::Util qw( min );

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::FestivalProduct - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        festival_product_id => 'festival_product_id',
        product_id          => 'product_id',
        festival_id         => 'festival_id',
        sale_price          => 'sale_price',
        sale_currency_id    => 'sale_currency_id',
        sale_volume_id      => 'sale_volume_id',
        company_id          => {
            product_id          => 'company_id',
        },
        comment             => 'comment',
    });
}

=head2 index

=cut

sub index :Path :Args(0) {

    # Listing of product types linking to grid views for each.
    my ( $self, $c, $festival_id ) = @_;

    my @categories = $c->model('DB::ProductCategory')->all(); 

    $c->stash->{categories} = \@categories;
}

=head2 load_form

=cut

sub load_form : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::FestivalProduct');

    $self->form_json_and_detach( $c, $rs, 'festival_product_id' );
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c, $festival_id, $category_id ) = @_;

    my ( $rs, $festival );
    if ( defined $festival_id ) {
        $festival = $c->model( 'DB::Festival' )->find({festival_id => $festival_id});
        unless ( $festival ) {
            $c->stash->{error} = qq{Festival ID "$festival_id" not found.};
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $festival->search_related(
            'festival_products',
            { 'product_id.product_category_id' => $category_id },
            {
                join     => { product_id => 'product_category_id' },
                prefetch => { product_id => 'product_category_id' },
            });
    }
    else {
        die('Error: festival_id not defined.');
    }
    $self->generate_json_and_detach( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $festival_id, $category_id ) = @_;

    my $festival = $c->model('DB::Festival')->find($festival_id);
    unless ( $festival ) {
        $c->flash->{error} = qq{Festival ID "$festival_id" not found.};
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }
    $c->stash->{festival} = $festival;

    my $category = $c->model('DB::ProductCategory')->find($category_id);
    unless ( $category ) {
        $c->flash->{error} = qq{Product category ID "$category_id" not found.};
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }
    $c->stash->{category} = $category;

    $self->get_default_currency( $c );
    $self->get_default_sale_volume( $c );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::FestivalProduct');

    # Structure of objects to be created/updated are stored in the
    # Catalyst context.
    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::FestivalProduct');

    # Database IDs of objects to be deleted are stored in the Catalyst context.
    $self->delete_from_resultset( $c, $rs );
}

=head2 view

=cut

sub view : Local {

    my ( $self, $c, $id ) = @_;

    my $object = $c->model('DB::FestivalProduct')->find($id);

    unless ( $object ) {
        $c->flash->{error} = "Error: FestivalProduct not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }

    $c->stash->{object}     = $object;
    $c->stash->{festival}   = $object->festival_id();

    return;
}

=head2 list_status

=cut

sub list_status : Local {

    my ( $self, $c, @args ) = @_;

    my $objects = $self->_derive_status_report( $c, @args );

    $c->stash->{objects} = $objects;

    $c->detach( $c->view( 'JSON' ) );
}

=head2 html_status_list

=cut

sub html_status_list : Local {

    my ( $self, $c, @args ) = @_;

    my $objects = $self->_derive_status_report( $c, @args );

    $c->stash->{objects} = $objects;

    # Don't include CSS and JS code.
    $c->stash->{generate_bare_html} = 1;

    return;
}

sub _derive_status_report : Private {

    my ( $self, $c, $festival_id, $category_id ) = @_;

    my $festival = $c->model('DB::Festival')->find($festival_id);

    unless ( $festival ) {
        $c->flash->{error} = qq{Festival ID "$festival_id" not found.};
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();
    }

    my ( $cond, $attr );
    if ( $category_id ) {
        $cond = { 'product_id.product_category_id' => $category_id };
        $attr = {  # Works on both FestivalProduct and ProductOrder.
            join => { product_id => 'product_category_id' }
        };
    }

    my $fp_rs = $festival->search_related('festival_products', $cond, $attr);
    my $po_rs = $festival->search_related('order_batches')
                          ->search_related('product_orders',
                                           { %$cond, is_final => 1 }, $attr);


    my %festprod;
    while ( my $po = $po_rs->next() ) {
        my $product = $po->product_id();
        my $company = $product->company_id();
        $festprod{ $po->get_column('product_id') } = {
            company      => $company->name(),
            location     => $company->loc_desc(),
            year_founded => $company->year_founded(),
            product      => $product->name(),
            abv          => $product->nominal_abv(),
            description  => $product->description(),
            status       =>  'Ordered',
        };
    }

    while ( my $fp = $fp_rs->next() ) {
        my $product_id = $fp->get_column('product_id');
        my $product = $fp->product_id();
        my $company = $product->company_id();
        $festprod{ $product_id } = {
            company      => $company->name(),
            location     => $company->loc_desc(),
            year_founded => $company->year_founded(),
            product      => $product->name(),
            abv          => $product->nominal_abv(),
            description  => $product->description(),
            status       =>  'Arrived',
        };

        my $cask_rs = $festival->search_related(
            'casks',
            { gyle_id => {
                'in' => [ map { $_->get_column('gyle_id') } $fp->gyles() ]
            }
          }
        );

        if ( $cask_rs->count() ) {
            my %caskstat_map = (
                is_vented    => 'Vented',
                is_tapped    => 'Tapped',
                is_ready     => 'Ready',
                is_condemned => 'Arrived',  # Totally non-committal, this is for public consumption.
            );
            my %caskstat;
            while ( my $cask = $cask_rs->next() ) {
                my $abv = $cask->gyle_id()->abv();
                $festprod{ $product_id }{abv} = $abv if defined $abv;
                foreach my $column ( keys %caskstat_map ) {
                    $caskstat{ $column } = 1 if $cask->$column;
                }
            }
            CASKSTAT:
            foreach my $key ( qw( is_condemned is_ready is_tapped is_vented ) ) {
                if ( $caskstat{ $key } ) {
                    if ( $key eq 'is_ready' ) {
                        my $amt_remaining = $self->_amount_remaining( $fp );
                        $festprod{ $product_id }{status} = defined $amt_remaining
                                                         ? "$amt_remaining Remaining"
                                                         : $caskstat_map{$key};
                    }
                    else {
                        $festprod{ $product_id }{status} = $caskstat_map{$key};
                    }
                    last CASKSTAT;
                }
            }
        }
    }

    return [ values %festprod ];
}

sub _amount_remaining : Private {

    my ( $self, $fp ) = @_;

    # This will need to convert everything into litres (both
    # ContainerSize and CaskMeasurement) via the ContainerMeasure
    # table, then convert back into whatever the ContainerSize units
    # are. Great fun.
    my $cask_rs = $fp->festival_id()->search_related(
        'casks',
        { gyle_id => {
            'in' => [ map { $_->get_column('gyle_id') } $fp->gyles() ]
        }
      }
    );

    my $output;
    if ( $cask_rs->count() ) {

        my $running_volume = 0;
        my $overall_measure;  # The output measurement unit.
        CASK:
        while ( my $cask = $cask_rs->next() ) {
            next CASK if $cask->is_condemned();
            my $cask_size = $cask->container_size_id();
            $overall_measure ||= $cask_size->container_measure_id();
            my $vol = $cask_size->container_volume()
                * $cask_size->container_measure_id()->litre_multiplier();
            if ( $cask->cask_measurements()->count() ) {
                my @dip_vols;
                foreach my $dip ( $cask->cask_measurements() ) {
                    push @dip_vols, $dip->volume() * $dip->container_measure_id()->litre_multiplier();
                }
                $vol = min @dip_vols;
            }
            $running_volume += $vol;
        }
        
        $output = $running_volume / $overall_measure->litre_multiplier();

        $output .= ' ' . $overall_measure->description() . 's';  # FIXME proper plural inflections
    }
    else {
        $output = 'None';
    }

    return $output;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
