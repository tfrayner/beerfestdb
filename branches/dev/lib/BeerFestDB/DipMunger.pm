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

package BeerFestDB::DipMunger;
use Moose::Role;
use namespace::autoclean;

use Memoize qw(memoize unmemoize);

sub munge_dips {

    my ( $self, $cask ) = @_;

    my $festival = $cask->festival_id;

    my $latest_batch_id = $self->_latest_dipbatch_with_data( $festival );

    return [] unless $latest_batch_id;

    my @batches = $festival->measurement_batches(
        undef,
        { order_by => { -asc => 'measurement_time' }},
    );

    my %dip = map { $_->get_column('time') => $_->get_column('volume') } $festival
        ->search_related(
            'measurement_batches',
            { 'cask_measurements.cask_id' => $cask->id() },
            { prefetch => 'cask_measurements',
              +select  => [ 'measurement_time', 'cask_measurements.volume' ],
              +as      => [ 'time',             'volume',                  ] }
        );

    my @ongoing;
    my $latest = $cask->container_size_id->container_volume();

    DIP:
    foreach my $batch ( @batches ) {
        my $vol = $dip{ $batch->measurement_time() };
        if ( defined $vol ) {
            push @ongoing, $vol;
            $latest = $vol;
        }
        else {
            push @ongoing, $latest;
        }
        last DIP if $batch->measurement_batch_id == $latest_batch_id;
    }

    return \@ongoing;
}

sub _latest_dipbatch_with_data {

    my ( $self, $festival ) = @_;

    my @batches = $festival->search_related('measurement_batches',
                                            undef,
                                            { order_by => { -asc => 'measurement_time' } });

    my $latest;

    foreach my $batch ( @batches ) {
        $latest = $batch if $batch->cask_measurements()->count() > 0;
    }

    return $latest ? $latest->measurement_batch_id() : undef;
}

memoize \&_latest_dipbatch_with_data;

sub forget_latest_dipbatch {

    my ( $self ) = @_;

    unmemoize \&_latest_dipbatch_with_data;
    memoize \&_latest_dipbatch_with_data;

    return;
}

=head1 NAME

BeerFestDB::DipMunger - Utility functions for CaskMeasurements.

=head1 DESCRIPTION

This is a Role class providing utility functions for dealing with
CaskMeasurement data in sparse database format.

=head1 METHODS

=cut



=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

1;
