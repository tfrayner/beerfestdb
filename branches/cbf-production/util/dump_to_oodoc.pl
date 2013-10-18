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

use BeerFestDB::ORM;
use BeerFestDB::Dumper::OODoc;
use BeerFestDB::Web;

sub parse_args {

    my ( $outfile, $template, $want_help );

    GetOptions(
        "f|filename=s" => \$outfile,
        "t|template=s" => \$template,
        "h|help"       => \$want_help,
    );

    if ($want_help) {
        pod2usage(
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 1,
        );
    }

    unless ( $outfile && $template ) {
        pod2usage(
            -message => qq{Please see "$0 -h" for further help notes.},
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 0,
        );
    }

    my $config = BeerFestDB::Web->config();

    return( $outfile, $config, $template );
}

########
# MAIN #
########

my ( $outfile, $config, $template ) = parse_args();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $dumper = BeerFestDB::Dumper::OODoc->new(
    database => $schema,
    filename => $outfile,
    template => $template,
    config   => $config->{'OODoc'},
);

$dumper->dump();

__END__

=head1 NAME

dump_to_oodoc.pl

=head1 SYNOPSIS

 dump_to_oodoc.pl -f <output file> -t <template file>

=head1 DESCRIPTION

This script can be used to dump out a defined set of information for
the beers for a given festival into OpenOffice ODF format.

=head2 OPTIONS

=over 2

=item -f

The output file to create. If the file already exists then new
information will be appended to it.

=item -t

A template ODT file containing the requisite style information.

=back

=head1 SEE ALSO

L<BeerFestDB::Dumper::OODoc>

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut
