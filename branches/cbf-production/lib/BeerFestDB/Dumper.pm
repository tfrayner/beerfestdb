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
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.01';

has 'database'  => ( is       => 'ro',
                     isa      => 'DBIx::Class::Schema',
                     required => 1 );

has '_festival' => ( is       => 'rw',
                     isa      => 'BeerFestDB::ORM::Festival' );

has '_order_batch' => ( is       => 'rw',
                        isa      => 'BeerFestDB::ORM::OrderBatch' );

sub festival {

    my ( $self, $fest ) = @_;

    if ( $fest ) {
        $self->_festival( $fest );
        return( $fest );
    }

    if ( $fest = $self->_festival() ) {
        return $fest;
    }

    $fest = $self->select_festival();

    $self->_festival($fest);

    return $fest;
}

sub select_festival {

    my ( $self ) = @_;

    # Just retrieve the casks for the festival in question. We need an
    # interactive menu here.
    my @festivals = $self->database->resultset('Festival')->all();

    my $wanted;

    SELECT:
    {
        warn("Please select the beer festival of interest:\n\n");
        foreach my $n ( 1..@festivals ) {
            my $fest = $festivals[$n-1];
            warn(sprintf("  %d: %d %s\n", $n, $fest->year, $fest->name));
        }
        warn("\n");
        chomp(my $select = <STDIN>);
        redo SELECT unless ( looks_like_number( $select )
                                 && ($wanted = $festivals[ $select-1 ]) );
    }

    return $wanted;
}

sub festival_casks {

    my ( $self ) = @_;

    my $fest = $self->festival();

    my @casks = $fest->search_related('casks')->all();

    return \@casks;
}

sub festival_products {

    my ( $self ) = @_;

    my $fest = $self->festival();

    my @products = $fest->search_related('festival_products')
                        ->search_related('product_id')->all();

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

    $batch = $self->select_order_batch();

    $self->_order_batch($batch);

    return $batch;
}

sub select_order_batch {

    my ( $self ) = @_;

    # Just retrieve the casks for the festival in question. We need an
    # interactive menu here.
    my @batches = $self->festival->order_batches();

    my $wanted;

    SELECT:
    {
        warn("Please select the order batch:\n\n");
        foreach my $n ( 1..@batches ) {
            my $batch = $batches[$n-1];
            warn(sprintf("  %d: %s %s\n", $n, $batch->description, $batch->order_date || q{}));
        }
        warn("\n");
        chomp(my $select = <STDIN>);
        redo SELECT unless ( looks_like_number( $select )
                                 && ($wanted = $batches[ $select-1 ]) );
    }

    return $wanted;
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

=item select_festival_casks

A method which will interactively ask the user for the festival of
interest, and return a list of casks for that festival.

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

