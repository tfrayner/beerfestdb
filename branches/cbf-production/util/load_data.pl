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

use BeerFestDB::Loader;
use BeerFestDB::Web;

########
# SUBS #
########

sub parse_args {

    my ( $input, $overwrite, $want_version, $want_help );

    GetOptions(
	"i|input=s"   => \$input,
	"o|overwrite" => \$overwrite,
        "h|help"      => \$want_help,
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

    return( $input, $config, $overwrite );
}

my ( $input, $config, $overwrite ) = parse_args();

########
# MAIN #
########

if ( $overwrite ) {
    print "Warning: you have asked to run the loader in 'overwrite' mode. Are you sure (y/N)? ";
    chomp(my $answer = <STDIN>);
    unless ( lc($answer) eq 'y' ) {
	die("User canceled script execution.\n");
    }
}

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $loader = BeerFestDB::Loader->new(
    database  => $schema,
    protected => ( $config->{'protected_classes'} || [] ),
    overwrite => $overwrite,
);

$loader->load( $input );

__END__

=head1 NAME

load_data.pl

=head1 SYNOPSIS

 load_data.pl -i <input tab-delimited text file>

=head1 DESCRIPTION

This script can be used to load data from a tab-delimited text file
into the database. See L<BeerFestDB::Loader> for more information.

=head2 OPTIONS

=over 2

=item -i

The tab-delimited file to import.

=item -o

Run the loader in overwrite mode. This is potentially dangerous.

=back

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut
