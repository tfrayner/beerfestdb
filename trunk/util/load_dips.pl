#!/usr/bin/env perl
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

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Config::YAML;
use Text::CSV_XS;
use Scalar::Util qw(looks_like_number);
use BeerFestDB::ORM;

use Data::Dumper;

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

sub select_dip_batch {

    my ( $festival ) = @_;

    my @batches = $festival->search_related(
        'measurement_batches', undef,
        { order_by => { -asc => 'measurement_time' } }
    );

    my $wanted;

    SELECT:
    {
        warn("Please select the dip batch to update:\n\n");
        foreach my $n ( 1..@batches ) {
            my $batch = $batches[$n-1];
            warn(sprintf("  %d: %s %s\n",
                         $n, $batch->measurement_time, $batch->description));
        }
        warn("\n");
        chomp(my $select = <STDIN>);
        redo SELECT unless ( looks_like_number( $select )
                                 && ($wanted = $batches[ $select-1 ]) );
    }

    return $wanted;
}

sub value_acceptable {

    my ( $value ) = @_;

    if ( defined $value && $value ne q{} ) {
        return 1;
    }

    return;
}

my ( $input, $config ) = parse_args();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $festname = $config->{'current_festival'}
    or die(qq{Error: Config option for current_festival has not been set.\n});
my $festival = $schema->resultset('Festival')->find({ name => $festname })
    or die(qq{Error retrieving festival "$festname" from the database.\n});

my $batch = select_dip_batch( $festival );

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

eval {
    $schema->txn_do(
        sub {
            MEAS:
            while ( my $line = $csv_parser->getline($fh) ) {
                next MEAS unless ( value_acceptable( $line->[0] )
                                && value_acceptable( $line->[1] ));
                my $cask = $schema->resultset('Cask')->find(
                    { festival_id      => $festival->id(),
                      cellar_reference => $line->[0] })
                    or die(qq{Error: Cask with cellar_reference "$line->[0]" }
                               . qq{not found for festival "$festname".\n});
                $schema->resultset('CaskMeasurement')->update_or_create({
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
    print("Dip data successfully loaded.\n");
}

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
