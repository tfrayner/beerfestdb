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
use Digest::SHA qw( sha1_hex );
use Carp;
use JSON::MaybeXS;

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
	product_name        => {
	    product_id          => 'name',
	},
        festival_id         => 'festival_id',
        festival_name       => {
            festival_id         => 'name',
        },
        festival_year       => {
            festival_id         => 'year',
        },
        sale_price          => 'sale_price',
        sale_currency_id    => 'sale_currency_id',
        sale_volume_id      => 'sale_volume_id',
        company_id          => {
            product_id          => 'company_id',
        },
        company_name        => {
            product_id          => {
		company_id          => 'name',
	    },
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

=head2 list_by_product

=cut

sub list_by_product : Local {

    my ( $self, $c, $product_id ) = @_;

    my $rs;
    if ( defined $product_id ) {
        $rs = $c->model( 'DB::FestivalProduct' )->search_rs( { product_id => $product_id } );
    }
    else {
        $c->stash->{error} = qq{Product ID not supplied.};
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }

    $self->generate_json_and_detach( $c, $rs );
}

=head2 list_by_company

=cut

sub list_by_company : Local {

    my ( $self, $c, $company_id ) = @_;

    my $rs;
    if ( defined $company_id ) {
        $rs = $c->model( 'DB::FestivalProduct' )
            ->search_rs( { 'product_id.company_id' => $company_id },
                         { join => 'product_id' } );
    }
    else {
        $c->stash->{error} = qq{Company ID not supplied.};
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
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

    $self->get_default_currency( $c );

    return;
}

=head2 list_status

=cut

sub list_status : Local {

    my ( $self, $c, @args ) = @_;

    my $objects;
    eval {
        $objects = $self->_derive_status_report( $c, @args );
    };

    if ( my $rc = $@ ) {
        $rc =~ s/\n \z//xms;
        $c->stash->{success} = JSON->false();
        $c->stash->{error}   = $rc;
    }
    else {
        $c->stash->{success} = JSON->true();
        $c->stash->{objects} = $objects;
    }

    $c->forward( 'View::JSON' );
}

=head2 html_status_list

=cut

sub html_status_list : Local {

    my ( $self, $c, @args ) = @_;

    my $objects;

    eval {
        $objects = $self->_derive_status_report( $c, @args );
    };
    if ( $@ ) {
        $c->flash->{error} = qq{JSON query error: $@};
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();
    }

    $c->stash->{objects} = $objects;

    # Don't include CSS and JS code.
    $c->stash->{generate_bare_html} = 1;

    return;
}

sub _sha1_hash : Private {

    my ( $self, $content ) = @_;

    my $sha1 = Digest::SHA->new;
    $sha1->add($content);

    return $sha1->hexdigest();
}

sub _build_product_data : Private {

    my ( $self, $product ) = @_;

    my $company = $product->company_id();
    my $year    = $company->year_founded();
    my $style   = $product->product_style_id();

    # I'm a little allergic to exposing internal database IDs to the
    # public.
    my $data = {
        id           => $self->_sha1_hash( $product->product_id() ),
        company      => $company->name(),
        company_id   => $self->_sha1_hash( $company->company_id() ),
        location     => $company->loc_desc(),
        year_founded => $year ? $year : undef,
        product      => $product->name(),
        abv          => $product->nominal_abv(),
        style        => $style ? $style->description() : undef,
        description  => $product->description(),
    };

    return( $data );
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

    # Figure out whether the festival is open or not.
    my @timeparts = gmtime();
    my $datenow = sprintf( "%04d%02d%02d",
                           $timeparts[5] + 1900,
                           $timeparts[4] + 1,
                           $timeparts[3] );
    my $opendate = $festival->fst_start_date()
        or die("Error: Attempt to create status report for festival without start date.\n");
    $opendate =~ s/-//g;
    my $festival_open = ( $datenow - $opendate >= 0 ) ? 1 : 0;

    my %festprod;

    # Don't check the order table once we're open.
    if ( ! $festival_open ) {
        while ( my $po = $po_rs->next() ) {
            my $product  = $po->product_id();
            my $prodhash = $self->_build_product_data( $product );
            $prodhash->{'status'}     = 'Ordered';
            $prodhash->{'css_status'} = 'ordered';
            $festprod{ $po->get_column('product_id') } = $prodhash;
        }
    }

    FP:
    while ( my $fp = $fp_rs->next() ) {
	my %gyleabv;
	foreach my $gyle ( $fp->gyles() ) {
	    $gyleabv{ $gyle->abv }++ if defined $gyle->abv;
	}
	my @gyleabvs = keys %gyleabv;
	
        my $product_id = $fp->get_column('product_id');
        my $product = $fp->product_id();

	# Gyles having multiple ABVs is a little beyond us here. Not
	# interested in taking an average. Similarly we fall back to
	# the nominal ABV if gyle ABV not known/recorded.
	my $abv = scalar @gyleabvs == 1
                ? $gyleabvs[0]
		: $product->nominal_abv();	    

        my $prodhash = $self->_build_product_data( $product );
        $prodhash->{'abv'}        = $abv;
        $prodhash->{'status'}     = 'Arrived';
        $prodhash->{'css_status'} = 'arrived';
        $festprod{ $product_id }{starting_volume} = undef;
        $festprod{ $product_id } = $prodhash;

        # Prior to opening, "Arrived" is all we really want.
        next FP unless $festival_open;

        my $cask_rs = $festival->search_related('cask_managements')
                               ->search_related('casks',
            { gyle_id => {
                'in' => [ map { $_->get_column('gyle_id') } $fp->gyles() ]
            }
          }
        );

        if ( my $not_condemned = $cask_rs->count() ) {

            # Check for condemned casks and ABVs deviated from nominal.
            while ( my $cask = $cask_rs->next() ) {
                my $abv = $cask->gyle_id()->abv();
                $festprod{ $product_id }{abv} = $abv if defined $abv;
                $not_condemned-- if ( $cask->is_condemned );
            }

            if ( $not_condemned == 0 ) {

                # All casks condemned. Totally non-committal, this
                # description is for public consumption.
                $festprod{ $product_id }{status}     = 'Sold Out';
                $festprod{ $product_id }{css_status} = 'sold_out';
            }
            else {

                # If not condemned, get the amount remaining.
                my ( $amt_remaining, $starting, $measure ) = $self->_amount_remaining( $fp );
                $festprod{ $product_id }{starting_volume} = $starting;
                if ( ! ( defined $amt_remaining && defined $measure ) ) {

                    # Shouldn't happen.
                    confess("Error: undef return from amount calculation.");
                }
                elsif ( $amt_remaining == 0 ) {
                    $festprod{ $product_id }{status}     = 'Sold Out';
                    $festprod{ $product_id }{css_status} = 'sold_out'; 
                }
                elsif ( $amt_remaining > 0 ) {

                    # FIXME proper plural inflections.
                    $festprod{ $product_id }{status}
                        = sprintf("%d %ss Remaining", $amt_remaining, $measure->description());
                    $festprod{ $product_id }{css_status} = 'product_remaining'; 
                }
                else {

                    # Again, shouldn't happen.
                    confess("Error: negative return from amount calculation.");
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
    my $cask_rs = $fp->festival_id()->search_related('cask_managements')
                                    ->search_related('casks',
        { gyle_id => {
            'in' => [ map { $_->get_column('gyle_id') } $fp->gyles() ]
        }
      }
    );

    # The output volume and measurement unit.
    my ( $remaining, $overall_measure );
    my $starting_volume = 0;
    if ( $cask_rs->count() ) {

        my $running_volume = 0;
        CASK:
        while ( my $cask = $cask_rs->next() ) {
            next CASK if $cask->is_condemned();
            my $cask_size = $cask->cask_management_id()->container_size_id();
            $overall_measure ||= $cask_size->container_measure_id();
            my $vol = $cask_size->container_volume()
                * $cask_size->container_measure_id()->litre_multiplier();
            $starting_volume += $vol;
            if ( $cask->cask_measurements()->count() ) {
                my @dip_vols;
                foreach my $dip ( $cask->cask_measurements() ) {
                    push @dip_vols, $dip->volume() * $dip->container_measure_id()->litre_multiplier();
                }
                $vol = min @dip_vols;
            }
            $running_volume += $vol;
        }
        
        $remaining = $running_volume / $overall_measure->litre_multiplier();
    }

    $starting_volume = $starting_volume / $overall_measure->litre_multiplier();

    # Undef return implies no Cask objects attached to Gyles for this FestivalProduct.
    return ( $remaining, $starting_volume, $overall_measure );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
