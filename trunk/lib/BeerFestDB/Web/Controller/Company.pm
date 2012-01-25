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

package BeerFestDB::Web::Controller::Company;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::Company - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        company_id        => 'company_id',
        name              => 'name',
        full_name         => 'full_name',
        loc_desc          => 'loc_desc',
        year_founded      => 'year_founded',
        url               => 'url',
        comment           => 'comment',
        company_region_id => 'company_region_id',
    });
}

=head2 load_form

=cut

sub load_form : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::Company');

    $self->form_json_and_detach( $c, $rs, 'company_id' );
}

=head2 view

=cut

sub view : Local {

    my ( $self, $c, $id ) = @_;

    my $object = $c->model('DB::Company')->find($id);

    unless ( $object ) {
        $c->flash->{error} = "Error: Company not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }

    $c->stash->{object}     = $object;

    return;
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs;

    my $query_id;
    if ( $query_id = $c->req()->params()->{ brewer_festival_id } ) {

        # Pull out all the brewers used for a given festival.
        my $festival = $c->model( 'DB::Festival' )->find({festival_id => $query_id});
        unless ( $festival ) {
            $c->stash->{error} = qq{Festival ID "$query_id" not found.};
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $festival->search_related('festival_products')
                       ->search_related('product_id')
                       ->search_related('company_id', undef, { distinct => 1 });        
    }
    if ( $query_id = $c->req()->params()->{ brewer_order_batch_id } ) {

        # Pull out all the brewers used for a given order batch (product orders).
        my $batch = $c->model( 'DB::OrderBatch' )->find({order_batch_id => $query_id});
        unless ( $batch ) {
            $c->stash->{error} = qq{OrderBatch ID "$query_id" not found.};
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $batch->search_related('product_orders')
                    ->search_related('product_id')
                    ->search_related('company_id', undef, { distinct => 1 });        
    }
    elsif ( $query_id = $c->req()->params()->{ supplier_order_batch_id } ) {

        # Pull out all the suppliers/distributors used for a given order batch.
        my $batch = $c->model( 'DB::OrderBatch' )->find({order_batch_id => $query_id});
        unless ( $batch ) {
            $c->stash->{error} = qq{OrderBatch ID "$query_id" not found.};
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $batch->search_related('product_orders')
                    ->search_related('distributor_company_id', undef, { distinct => 1 });
    }
    else {

        # The default is to pull out everything. We're trying to cut back though...
        $rs = $c->model( 'DB::Company' );
    }

    $self->generate_json_and_detach( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Company' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Company' );

    $self->delete_from_resultset( $c, $rs );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
