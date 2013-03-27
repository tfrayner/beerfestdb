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

=head1 NAME

BeerFestDB::DipMunger - Utility functions for CaskMeasurements.

=head1 DESCRIPTION

This is a Role class providing utility functions for dealing with
CaskMeasurement data in sparse database format.

=head1 METHODS

=head2 munge_dips

Given a BeerFestDB::ORM::Cask row this method simply returns a list of
dip measurements up to and including the latest dip for which any
figures are available within a Festival. This method is used to fill
in gaps in the record caused by sparse recording of dip figures (e.g.,
we don't dip when either full or empty).

=cut

sub munge_dips {

    my ( $self, $cask ) = @_;

    my $caskman = $cask->cask_management_id();

    my $festival = $caskman->festival_id;

    my $latest_batch_id = $self->_latest_dipbatch_with_data( $festival );

    return [] unless $latest_batch_id;

    my @batches = $festival->measurement_batches(
        undef,
        { order_by => { -asc => 'measurement_time' }},
    );

    my %dip = map { $_->get_column('time') => { volume     => $_->get_column('volume'),
                                                multiplier => $_->get_column('multiplier') } }
        $festival->search_related(
            'measurement_batches',
            { 'cask_measurements.cask_id' => $cask->id() },
            { prefetch => { 'cask_measurements' => 'container_measure_id' },
              +select  => [ 'measurement_time',
                            'cask_measurements.volume',
                            'container_measure_id.litre_multiplier', ],
              +as      => [ 'time',
                            'volume',
                            'multiplier', ] }
        );

    my %ongoing;
    my $latest = $caskman->container_size_id->container_volume();
    my $denom  = $caskman->container_size_id->container_measure_id->litre_multiplier();

    DIP:
    foreach my $batch ( @batches ) {
        my $d = $dip{ $batch->measurement_time() };
        if ( defined $d && defined $d->{'volume'} ) {

            # Convert $vol into the same units used by the cask
            # container_size (in practice the units are generally
            # identical in any case). Beware floating point shennanigans here.
            my $vol = $d->{'volume'} * ( $d->{'multiplier'} / $denom );
            $ongoing{ $batch->id } = $vol;
            $latest = $vol;
        }
        else {
            $ongoing{ $batch->id } = $latest;
        }
        last DIP if $batch->measurement_batch_id == $latest_batch_id;
    }

    return \%ongoing;
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

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

1;
