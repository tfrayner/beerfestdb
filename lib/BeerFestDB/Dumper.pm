#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010-2013 Tim F. Rayner
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

package BeerFestDB::Dumper;

use 5.008;

use strict; 
use warnings;

use Moose;

use Carp;

our $VERSION = '0.01';

has 'database'  => ( is       => 'ro',
                     isa      => 'DBIx::Class::Schema',
                     required => 1 );

# Used to filter the objects to be dumped (only cask_management at the
# moment; gyle filtering may be implemented in subclasses).
has 'cask_ids'   => ( is       => 'ro',
                      isa      => 'ArrayRef',
                      required => 1,
                      default  => sub { [] } );

has '_order_batch' => ( is       => 'rw',
                        isa      => 'BeerFestDB::ORM::OrderBatch' );

with 'BeerFestDB::MenuSelector';

sub festival_casks {

    my ( $self ) = @_;

    my $fest = $self->festival();

    my $cmset = (scalar grep { defined $_ } @{ $self->cask_ids })
        ? $fest->search_related_rs('cask_managements', { cellar_reference => $self->cask_ids } )
        : $fest->search_related_rs('cask_managements');
    my @casks = $cmset->search_related_rs('casks')->all();

    return \@casks;
}

sub festival_cask_managements {

    my ( $self ) = @_;

    my $fest = $self->festival();

    my $cmset = (scalar grep { defined $_ } @{ $self->cask_ids })
        ? $fest->search_related_rs('cask_managements', { cellar_reference => $self->cask_ids } )
        : $fest->search_related_rs('cask_managements');
    my @caskmans = $cmset->all();

    return \@caskmans
}

sub festival_products {

    my ( $self ) = @_;

    my $fest = $self->festival();

    my @products = $fest->search_related_rs('festival_products')
                        ->search_related_rs('product_id')->all();

    return \@products;
}

sub order_batch {

    my ( $self, $batch ) = @_;

    if ( $batch ) {
        $self->_order_batch( $batch );
        return( $batch );
    }

    if ( $batch = $self->_order_batch() ) {
        return $batch;
    }

    $batch = $self->select_order_batch( $self->festival );

    $self->_order_batch($batch);

    return $batch;
}

sub festival_orders {

    my ( $self ) = @_;

    my $fest = $self->festival();

    my @orders = $fest->search_related('order_batches')
                      ->search_related('product_orders', { is_final => 1 })->all();

    return \@orders;
}

sub festival_distributors {

    my ( $self ) = @_;

    my $fest = $self->festival();

    my @distributors = $fest->search_related('order_batches')
                            ->search_related('product_orders', { is_final => 1 })
                            ->search_related('distributor_company_id', undef, { distinct => 1})
                            ->all();
    
    return \@distributors;
}

sub order_batch_distributors {

    my ( $self ) = @_;

    my $batch = $self->order_batch();

    my @distributors = $batch->search_related('product_orders', { is_final => 1 })
                             ->search_related('distributor_company_id', undef, { distinct => 1 })
                             ->all();

    return \@distributors;
}

sub format_price {

    my ( $self, $price, $format ) = @_;

    return 'STAFF' unless $price;

    my @digits = split //, $price;

    my $formatted = q{};

    POS:
    foreach my $pos ( 1..length($format) ) {
        my $f = substr($format, -$pos, 1);
        if ( $f !~ /[#0]/ ) {
            $formatted = $f . $formatted;
            next POS;
        }
        my $num = pop @digits;
        last POS if ( $f eq '#' && ! defined $num );
        if ( $f eq '0' ) {
            $num ||= 0;
            $formatted = $num . $formatted;
        }
        else {
            die(qq{Error: Unrecognised formatting symbol: "$f".\n});
        }
    }

    return $formatted;
}

1;
__END__

=head1 NAME

BeerFestDB::Dumper - Abstract superclass for data dumper classes.

=head1 SYNOPSIS

 use Moose
 extends 'BeerFestDB::Dumper';

=head1 DESCRIPTION

This is an abstract class designed to be extended by the various
Dumper subclasses.

=head2 METHODS

=over 2

=item festival_casks

Returns a list of casks for the configured current_festival, or the
festival interactively selected from a menu by the user.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<BeerFestDB::Dumper::Template>, L<BeerFestDB::Dumper::OODoc>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut

