#!/usr/bin/env perl
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

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Scalar::Util qw(looks_like_number);
use BeerFestDB::ORM;
use BeerFestDB::Web;

use Data::Dumper;

package DipLoader;

use Moose;

has 'database'  => ( is       => 'ro',
                     isa      => 'DBIx::Class::Schema',
                     required => 1 );

with 'BeerFestDB::Role::MenuSelector';

with 'BeerFestDB::Role::CsvParser';

sub value_acceptable {

    my ( $value ) = @_;

    if ( defined $value && $value ne q{} ) {
        return 1;
    }

    return;
}

sub load {

    my ( $self ) = @_;

    my $batch = $self->select_dip_batch();

    my $db = $self->database;

    eval {
        $db->txn_do(
            sub {
                MEAS:
                while ( my $line = $self->getline() ) {
                    next MEAS unless ( scalar @$line > 1
                                    && value_acceptable( $line->[0] )
                                        && value_acceptable( $line->[1] ));
                    my $cask = $db->resultset('Cask')->find(
                        { 'cask_management_id.festival_id'      => $self->festival->id(),
                          'cask_management_id.cellar_reference' => $line->[0] },
                        { join => 'cask_management_id' } )
                        or die(qq{Error: Cask with cellar_reference "$line->[0]" }
                               . qq{not found.\n});

                    # Avoid total nonsense dips.
                    my $caskvol = $cask->cask_management_id->container_size_id->container_volume;
                    if ( $line->[1] > $caskvol ) {
                        die(sprintf("Dip figure of %.1f for cask %i larger than cask size %i.\n",
                                    $line->[1], $line->[0], $caskvol))
                    }

                    # Warn on oddities.
                    my @dips =
                        $cask->search_related(
                            'cask_measurements',
                            undef,
                            { join => 'measurement_batch_id',
                              order_by => {
                                  -desc => 'measurement_batch_id.measurement_time'
                              },
                          }
                        );
                    if ( scalar @dips > 0 ) {
                        if ( $line->[1] > $dips[0]->volume ) {
                            warn(sprintf("Dip figure for cask %i (%.1f) is higher than the previous dip (%.1f).",
                                         $line->[0], $line->[1], $dips[0]->volume))
                        }
                    }

                    $db->resultset('CaskMeasurement')->update_or_create({
                        cask_id              => $cask->id(),
                        measurement_batch_id => $batch->id(),
                        volume               => $line->[1],
                        container_measure_id => $cask->cask_management_id()->container_size_id()
                                                     ->get_column('container_measure_id'),
                    });
                }
            }
        );
    };
    if ( $@ ) {
        die(qq{Errors encountered during load:\n\n$@\n});
    }
    else {
        $self->confirm_eof();
        warn("Dip data successfully loaded.\n");
    }

    return;
}

package main;

sub parse_args {

    my ( $input, $want_help );

    GetOptions(
        "i|input=s"  => \$input,
        "h|help"     => \$want_help,
    );

    if ($want_help) {
        pod2usage(
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 1,
        );
    }

    unless ( $input ) {
        pod2usage(
            -message => qq{Please see "$0 -h" for further help notes.},
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 0,
        );
    }

    my $config = BeerFestDB::Web->config();

    return( $input, $config );
}

my ( $input, $config ) = parse_args();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $loader = DipLoader->new( database => $schema, csv_file => $input );

$loader->load();

__END__

=head1 NAME

load_dips.pl

=head1 SYNOPSIS

 load_dips.pl -i <list of dip figures>

=head1 DESCRIPTION

A script used to bulk-load dip figures. The data should be in a
tab-delimited format with just two columns corresponding to the cask
festival unique ID number and the dip reading measured in the same
units as the cask size (i.e., usually gallons).

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut
