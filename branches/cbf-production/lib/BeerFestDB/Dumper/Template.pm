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

package BeerFestDB::Dumper::Template;

use 5.008;

use strict; 
use warnings;

use Moose;

use Carp;
use Scalar::Util qw(looks_like_number);
use List::Util qw(first);
use Storable qw(dclone);
use Template;
use POSIX qw(ceil);

our $VERSION = '0.01';

extends 'BeerFestDB::Dumper';

has 'template'   => ( is       => 'ro',
                      isa      => 'Str',
                      required => 1 );

has 'filehandle' => ( is       => 'ro',
                      isa      => 'FileHandle',
                      required => 1,
                      default  => sub { \*STDOUT } );

has 'logos'      => ( is       => 'ro',
                      isa      => 'ArrayRef',
                      required => 1,
                      default  => sub { [] } );

has 'dump_class'  => ( is       => 'ro',
                       isa      => 'Str',
                       required => 1,
                       default  => 'product' );

sub BUILD {

    my ( $self, $params ) = @_;

    my $class = $params->{'dump_class'};
    if ( defined $class ) {
        unless ( first { $class eq $_ } qw(cask gyle product product_order distributor) ) {
            confess(qq{Error: Unsupported dump class "$class"});
        }
    }

    return;
}

sub product_hash {

    my ( $self, $product ) = @_;

    my $fest = $self->festival();
    my $fp   = $product->search_related('festival_products',
					{ festival_id => $fest->festival_id })->first();

    # N.B. Changes here need to be documented in the POD.
    my %prodhash = (
        brewery  => $product->company_id->name(),
	location => $product->company_id->loc_desc(),
        product  => $product->name(),
        style    => $product->product_style_id()
                    ? $product->product_style_id()->description() : q{},
        category => $product->product_category_id()->description(),
        abv      => $product->nominal_abv(),
        sale_volume => $fp->sale_volume_id()->description(),
        notes    => $product->description(),
    );

    my $currency = $fp->sale_currency_id();
    my $format   = $currency->currency_format();
    $prodhash{currency} = $currency->currency_symbol();

    $prodhash{price}   = $self->format_price( $fp->sale_price(), $format );
    if ( looks_like_number( $prodhash{price} ) ) {
        $prodhash{half_price}
            = $self->format_price( ceil($fp->sale_price() / 2), $format );
    }
    else {
        $prodhash{half_price} = $prodhash{price};
    }

    return \%prodhash;
}

sub order_hash {

    my ( $self, $order ) = @_;

    my $fest = $self->festival();

    # N.B. Changes here need to be documented in the POD. FIXME this is not documented at all yet.
    my %orderhash = (
        brewery     => $order->product_id->company_id->name(),
        product     => $order->product_id->name(),
        distributor => $order->distributor_company_id->name(),
        cask_size   => $order->container_size_id->container_volume(),
        cask_count  => $order->cask_count(),
    );

    my $currency = $order->currency_id();
    my $format   = $currency->currency_format();
    $orderhash{currency} = $currency->currency_symbol();
#    use Data::Dumper; warn Dumper [$format, $order->advertised_price()];
#    $orderhash{price}    = $self->format_price( $order->advertised_price(), $format ); FIXME

    return \%orderhash;
}

sub distributor_hash {

    my ( $self, $dist ) = @_;

    my $fest       = $self->festival();
    my $orderbatch = $self->order_batch();

    my $ct = $self->database()->resultset('ContactType')->find({ description => 'Sales' })
        or croak(qq{Cannot find 'Sales' ContactType in database.});

    my $contact = $dist->search_related('contacts', {contact_type_id => $ct->id})->first()
        or croak(sprintf(qq{Cannot find 'Sales' contact for '%s'.}, $dist->name()));
    
    my %disthash = (
        id         => $dist->id(),
        name       => $dist->name(),
        full_name  => $dist->full_name(),
        address    => $contact->street_address(),
        postcode   => $contact->postcode(),
        batch_id   => $orderbatch->id(),
    );

    my $order_rs
        = $dist->search_related('product_orders',
                                { order_batch_id => $orderbatch->id(),
                                  is_final       => 1 });
    
    my @orderlist;
    while ( my $order = $order_rs->next() ) {
        push @orderlist, $self->order_hash( $order );
    }
    $disthash{'orders'} = \@orderlist;

    return \%disthash;
}

sub update_gyle_hash {

    my ( $self, $gylehash, $gyle ) = @_;

    # N.B. Changes here need to be documented in the POD.
    $gylehash ||= {};

    # This potentially overwrites the "nominal" ABV from the product
    # table with the *actual* gyle ABV.
    if ( defined $gyle->abv() ) {
        $gylehash->{abv} = $gyle->abv();
    }

    return $gylehash;
}

sub update_cask_hash {

    my ( $self, $caskhash, $cask ) = @_;

    # N.B. Changes here need to be documented in the POD.
    $caskhash ||= {};
    $caskhash->{number}      = $cask->internal_reference();
    $caskhash->{festival_id} = $cask->cellar_reference();
    $caskhash->{size}        = $cask->container_size_id
          ? $cask->container_size_id->container_volume() : q{};

    return $caskhash;
}

sub dump {

    my ( $self ) = @_;

    my ( @template_data, %stillage );
    if ( $self->dump_class eq 'cask' ) {
        foreach my $cask ( @{ $self->festival_casks() } ) {
            my $caskhash = $self->product_hash(
                $cask->gyle_id()->festival_product_id()->product_id()
            );
            $self->update_gyle_hash( $caskhash, $cask->gyle_id() );
            $self->update_cask_hash( $caskhash, $cask );

            push @template_data, $caskhash;

            my $stillage_name = $cask->stillage_location_id()
                                ? $cask->stillage_location_id()->description() : '';
            push @{ $stillage{ $stillage_name } }, $caskhash;
        }
    }
    elsif ( $self->dump_class eq 'gyle' ) {
        foreach my $product ( @{ $self->festival_products } ) {
	    my @gyles =
		$product->search_related('festival_products')
                        ->search_related('gyles', 
					 { 'casks.festival_id' => $self->festival->id() },
					 {
					     prefetch => { casks => 'festival_id' },
					     join     => { casks => 'festival_id' },
					 });
            foreach my $gyle ( @gyles ) {
                my $gylehash = $self->product_hash( $gyle->festival_product_id()->product_id() );
                $self->update_gyle_hash( $gylehash, $gyle );

                push @template_data, $gylehash;

                # For typical use-case this might be better done by bar rather than stillage FIXME.
                my %stillage_seen;
                STILLAGE:
                foreach my $cask ( $gyle->search_related('casks',
                                                         { festival_id => $self->festival->id() }) ) { 
                    my $stillage_name = $cask->stillage_location_id()
                        ? $cask->stillage_location_id()->description() : '';
                    next STILLAGE if $stillage_seen{ $stillage_name }++;
                    push @{ $stillage{ $stillage_name } }, $gylehash;
                }
            }
        }
    }
    elsif ( $self->dump_class eq 'product' ) {
        foreach my $product ( @{ $self->festival_products() } ) {
            my $prodhash = $self->product_hash( $product );
            push @template_data, $prodhash;
        }
    }
    elsif ( $self->dump_class eq 'product_order' ) {
        foreach my $order ( @{ $self->festival_orders() } ) {
            my $orderhash = $self->order_hash( $order );
            push @template_data, $orderhash;
        }
    }
    elsif ( $self->dump_class eq 'distributor' ) {
        foreach my $dist ( @{ $self->festival_distributors() } ) {
            my $disthash = $self->distributor_hash( $dist );
            push @template_data, $disthash;
        }
    }
    else {
        confess(sprintf(qq{Attempt to dump data from unsupported class "%s"}, $self->dump_class));
    }

    my $vars = {
        logos      => $self->logos(),
        objects    => \@template_data,
        stillages  => \%stillage,
    };

    # We define a custom title case filter for convenience.
    my $template = Template->new(
	FILTERS => {titlecase => sub { join(' ', map { ucfirst $_ } split / +/, lc($_[0])) }}
    )   or die( "Cannot create Template object: " . Template->error() );

    $template->process($self->template(), $vars, $self->filehandle() )
        or die( "Template processing error: " . $template->error() );

    return;
}

1;
__END__

=head1 NAME

BeerFestDB::Dumper::Template - Export data via Template Toolkit

=head1 SYNOPSIS

 use BeerFestDB::Dumper::Template;
 
 # $rs is a DBIx::Class::ResultSet; @logos is an array of image file names.
 my $t = BeerFestDB::Dumper::Template->new( template => 'template.tt2',
                                            logos    => \@logos );
 $t->dump( $rs );

=head1 DESCRIPTION

This module describes a Moose class which can be used to process Cask
resultsets through a given Template Toolkit template. This can be used
to generate cask-end signs, HTML listings of the available beers,
conceivably even a full beer festival programme.

=head2 DETAILS

Currently the script defines the following variables which may be
referenced in the template:

=over 2

=item casks

A list of cask hashrefs, each of which has the following keys:

=over 2

=item brewery

The original brewer of the product.

=item location

The location of the brewery.

=item product

The name of the beer, cider, or whatever.

=item number

(Cask-level export only). The internal reference number for the cask.

=item festival_id

(Cask-level export only). The unique festival ID for the cask.

=item size

(Cask-level export only). The size of the cask (units not currently reported).

=item category

The product category ("beer", "cider" etc.).

=item style

The product style ("Stout", "Best Bitter", "Medium Sweet" etc.).

=item notes

A description of the product (e.g., beer tasting notes).

=item abv

The ABV, obviously.

=item currency

The currency used for sales.

=item price

The price per sale unit (typically price per pint).

=item half_price

The price per half sale unit.

=item sale_volume

The sale unit itself.

=back

=item stillages

A hashref keyed by stillage names linked to arrayrefs of cask hashrefs as
documented above.

=item logos

An arrayref containing the names of image files which can be
referenced in the template to place logos etc.

=back

=head2 OPTIONS

=over 2

=item template

The template file to use.

=item filehandle

The output filehandle (default STDOUT).

=item logos

An arrayref containing logo file names to pass through to the templates.

=item dump_class

A string indicating the level at which to dump out data. Can be one of
"cask", "gyle", "product" or "product_order".

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<BeerFestDB::Dumper>, L<BeerFestDB::Dumper::OODoc>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut

