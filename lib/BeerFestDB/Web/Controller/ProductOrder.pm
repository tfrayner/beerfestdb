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

package BeerFestDB::Web::Controller::ProductOrder;
use Moose;
use namespace::autoclean;
use JSON::MaybeXS;

BEGIN {extends 'BeerFestDB::Web::Controller'};
with 'BeerFestDB::CaskPreloader';

=head1 NAME

BeerFestDB::Web::Controller::ProductOrder - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        product_order_id  => 'product_order_id',
        company_id        => {
            product_id  => 'company_id',
        },
        product_id        => 'product_id',
        order_batch_id    => 'order_batch_id',
        festival_id       => {
            order_batch_id => 'festival_id',
        },
        distributor_id    => 'distributor_company_id',
        container_size_id => 'container_size_id',
        cask_count        => 'cask_count',
        currency_id       => 'currency_id',
        price             => 'advertised_price',
        is_final          => 'is_final',
        is_received       => 'is_received',
        is_sale_or_return => 'is_sale_or_return',
        comment           => 'comment',
    });
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c, $order_batch_id, $category_id ) = @_;

    # This method is intended to generally work with a defined
    # order_batch_id; however, since it was based on the equivalent
    # action in Product, it can in principle support a listing of all
    # orders ever.

    my ( $cond, $attrs );
    if ( defined $category_id ) {
        $cond  = { 'product_id.product_category_id' => $category_id };
        $attrs = { join => { product_id => 'product_category_id' } };
    }

    my ( $rs, $order_batch );
    if ( defined $order_batch_id ) {
        $order_batch = $c->model( 'DB::OrderBatch' )->find({
            order_batch_id => $order_batch_id});
        unless ( $order_batch ) {
            $c->stash->{error} = 'OrderBatch not found.';
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $order_batch->search_related('product_orders', $cond, $attrs)
    }
    else {
        $rs = $c->model( 'DB::ProductOrder' )->search_rs( $cond, $attrs );
    }

    $self->generate_json_and_detach( $c, $rs );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductOrder' );

    my $data = $self->decode_json_changes($c);

    eval {
        $rs->result_source()->schema()->txn_do(
            sub { $self->_save_records( $c, $rs, $data ); }
        );
    };
    if ( $@ ) {
        $self->detach_with_txn_failure( $c, $@ );
    }

    $c->stash->{ 'success' } = JSON->true();
    $c->forward( 'View::JSON' );
}

sub _save_records : Private {

    my ( $self, $c, $rs, $data ) = @_;

    # First we check that we haven't been passed records marked as
    # is_received more than once.
    my @received;
    foreach my $rec ( @{ $data } ) {
        if ( exists $rec->{ 'is_received' } && $rec->{ 'is_received' } ) {
            if ( my $po = $rs->find( $rec->{ 'product_order_id' } ) ) {
                if ( $po->is_received() ) {
                    die("Product Order set as is_received"
                            . " was already is_received in database.");
                }
            }
            $rec->{ 'is_final' } = 1; # This is implied.
            push @received, $rec;
        }
    }

    # Create the core ProductOrder records in the database.
    foreach my $rec ( @{ $data } ) {
        $self->build_database_object( $rec, $c, $rs );
    }

    # Copy any arrived products into FestivalProduct et al.
    foreach my $rec ( @received ) {

        # Failing to find the DB object is now an error (and really should never happen).
        my $po = $rs->find( $rec->{ 'product_order_id' } )
            or die("Unable to retrieve loaded product order");

        my $default_currency = $c->model('DB::Currency')->find({
            currency_code => $c->config->{'default_currency'},
        }) or die("Unable to retrieve default currency; check config settings.");

        my $default_sale_vol = $c->model('DB::SaleVolume')->find({
            description => $c->config->{'default_sale_volume'},
        }) or die("Unable to retrieve default sale volume; check config settings.");

        my $festival_id = $po->order_batch_id()->get_column('festival_id');
        my $product_id  = $po->get_column('product_id');
        my $currency_id = $default_currency->get_column('currency_id');

        my $fp = $c->model('DB::FestivalProduct')->find_or_create({
            festival_id      => $festival_id,
            sale_volume_id   => $default_sale_vol->get_column('sale_volume_id'),
            sale_currency_id => $currency_id,
            product_id       => $product_id,
        });
        my $fp_id = $fp->get_column('festival_product_id');

        # This should really be constrained somehow to control the
        # number of gyles created; I'm not sure how though - we might
        # need to actually track gyle information, which is not always
        # available. FIXME?
        my $gyle = $c->model('DB::Gyle')->find_or_create({
            company_id          => $po->product_id()->get_column('company_id'),
            festival_product_id => $fp_id,
            internal_reference  => 'auto-generated',
            comment             => 'Gyle automatically generated upon cask receipt.',
        });

        $self->preload_product_order( $po );

        # If we get here we must have synchronised product_order and
        # cask_management.
        foreach my $caskman ( $po->cask_managements() ) {
            $c->model('DB::Cask')->find_or_create({
                cask_management_id => $caskman,
                gyle_id            => $gyle,
            });
        }
    }

    return;
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductOrder' );

    $self->delete_from_resultset( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $order_batch_id, $category_id ) = @_;

    if ( defined $order_batch_id ) {
        my $order_batch = $c->model('DB::OrderBatch')->find($order_batch_id);
        unless ( $order_batch ) {
            $c->flash->{error} = "Error: OrderBatch not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{order_batch} = $order_batch;
        $c->stash->{festival}    = $order_batch->festival_id();
    }

    # It's not clear yet whether splitting orders by category is
    # actually desirable.
    if ( defined $category_id ) {
        my $category = $c->model('DB::ProductCategory')->find($category_id);
        unless ( $category ) {
            $c->flash->{error} = "Error: Product category not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{category} = $category;
    }

    $self->get_default_currency( $c );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
