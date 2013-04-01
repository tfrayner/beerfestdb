#!/usr/bin/env perl
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

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Config::YAML;
use Text::CSV_XS;
use Scalar::Util qw(looks_like_number);
use BeerFestDB::ORM;

use Data::Dumper;

package DipLoader;

use Moose;

has 'database'  => ( is       => 'ro',
                     isa      => 'DBIx::Class::Schema',
                     required => 1 );

with 'BeerFestDB::MenuSelector';

sub value_acceptable {

    my ( $value ) = @_;

    if ( defined $value && $value ne q{} ) {
        return 1;
    }

    return;
}

sub load {

    my ( $self, $input ) = @_;

    my $batch = $self->select_dip_batch();

    my $csv_parser = Text::CSV_XS->new(
        {   sep_char    => qq{\t},
            quote_char  => qq{"},                   # default
            escape_char => qq{"},                   # default
            binary      => 1,
            allow_loose_quotes => 1,
        }
    );

    open(my $fh, '<', $input)
        or die(qq{Error: unable to open input file "$input".\n});

    my $db = $self->database;

    eval {
        $db->txn_do(
            sub {
                MEAS:
                while ( my $line = $csv_parser->getline($fh) ) {
                    next MEAS unless ( scalar @$line > 1
                                    && value_acceptable( $line->[0] )
                                        && value_acceptable( $line->[1] ));
                    my $cask = $db->resultset('Cask')->find(
                        { festival_id      => $self->festival->id(),
                          cellar_reference => $line->[0] })
                        or die(qq{Error: Cask with cellar_reference "$line->[0]" }
                                   . qq{not found.\n});
                    $db->resultset('CaskMeasurement')->update_or_create({
                        cask_id              => $cask->id(),
                        measurement_batch_id => $batch->id(),
                        volume               => $line->[1],
                        container_measure_id => $cask->container_size_id()
                                                     ->get_column('container_measure_id'),
                    });
                }
            }
        );
    };
    if ( $@ ) {
        die(qq{Errors encountered during load:\n\n$@});
    }
    else {
        
        # Check that parsing completed successfully.
        my ( $error, $mess ) = $csv_parser->error_diag();
        unless ( $error == 2012 ) {    # 2012 is the Text::CSV_XS EOF code.
            die(sprintf(
		"Error in tab-delimited format: %s. Bad input was:\n\n%s\n",
		$mess,
		$csv_parser->error_input()));
        }
        
        print("Dip data successfully loaded.\n");
    }

    return;
}

package main;

sub parse_args {

    my ( $input, $conffile, $want_help );

    GetOptions(
	"i|input=s"  => \$input,
        "c|config=s" => \$conffile,        
        "h|help"     => \$want_help,
    );

    if ($want_help) {
        pod2usage(
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 1,
        );
    }

    $conffile ||= 'beerfestdb_web.yml';

    unless ( $input && $conffile ) {
        pod2usage(
            -message => qq{Please see "$0 -h" for further help notes.},
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 0,
        );
    }

    my $config = Config::YAML->new( config => $conffile );

    return( $input, $config );
}

my ( $input, $config ) = parse_args();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $loader = DipLoader->new( database => $schema );

$loader->load( $input );

__END__

=head1 NAME

load_dips.pl

=head1 SYNOPSIS

 load_dips.pl -i <list of dip figures> -c <config file>

=head1 DESCRIPTION

A script used to bulk-load dip figures. The data should be in a
tab-delimited format with just two columns corresponding to the cask
festival unique ID number and the dip reading measured in the same
units as the cask size (i.e., usually gallons).

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut
