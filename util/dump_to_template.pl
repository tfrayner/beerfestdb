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
use Cwd;

use BeerFestDB::ORM;
use BeerFestDB::Dumper::Template;
use BeerFestDB::Web;

sub parse_args {

    my ( $templatefile, $logofile, $objectlevel, $split, $outdir, $force, $filterstr, $want_help );

    GetOptions(
        "t|template=s" => \$templatefile,
        "l|logo=s"     => \$logofile,
        "o|objects=s"  => \$objectlevel,
        "h|help"       => \$want_help,
        "s|split-output" => \$split,
        "d|output-dir=s" => \$outdir,
        "f|force-overwrite" => \$force,
        "filters=s"      => \$filterstr,
    );

    if ($want_help) {
        pod2usage(
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 1,
        );
    }

    $objectlevel ||= 'cask';
    $outdir      ||= getcwd;

    unless ( $templatefile ) {
        pod2usage(
            -message => qq{Please see "$0 -h" for further help notes.},
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 0,
        );
    }

    my $config = BeerFestDB::Web->config();

    my $filters = [];
    if ( $filterstr ) {
        $filters = [ map { [ split /=/, $_ ] } split /,/, $filterstr ];
    }

    return( $templatefile, $logofile, $config, $objectlevel, $outdir, $split, $force, $filters );
}

########
# MAIN #
########

my ( $templatefile, $logofile, $config, $objectlevel,
     $outdir, $split, $force, $filters ) = parse_args();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $dumper = BeerFestDB::Dumper::Template->new(
    database => $schema,
    template => $templatefile,
    logos    => [ $logofile ],
    dump_class => $objectlevel,
    split_output => $split,
    output_dir   => $outdir,
    overwrite    => $force,
    filters      => $filters,
);

$dumper->dump();

__END__

=head1 NAME

dump_to_template.pl

=head1 SYNOPSIS

 dump_to_template.pl -t <template file> -l <logo file>

=head1 DESCRIPTION

This is a general-purpose script used to dump information 
held in the BeerFestDB database into a variety of file formats. It
works by taking a Template Toolkit-style template file, and applying
it to the information held in the database. See
L<BeerFestDB::Dumper::Template> for details on how variables are
passed into the template.

=head2 OPTIONS

=over 2

=item -t

The Template Toolkit file to apply to the data.

=item -l

An optional logo file, the name of which will be passed into the
template file as the first element of the "logos" array.

=item -o

Indicate the database class to use for dumping. See
L<BeerFestDB::Dumper::Template> for a list of acceptable options. The
default is 'cask'.

=item -d

The output directory into which to write files.

=item -s

Generate output latex files split by the object level used for dumping
(-o, above). The default behaviour is to write directly to STDOUT.

=item -f

Force overwriting of pre-existing output files when the -s option is used.

=item --filters

An optional set of filters defining objects to be removed from the
dumped data. These filters must be specified as a comma-separated list
of key=value pairs, like so:

 --filters 'cask_size_name=30L KeyKeg,cask_size_name=20L KeyKeg,category=cider'

Beware of spaces in the filter string; all spaces are interpreted
literally and will not be stripped from the applied filters. The
filter names are defined by the code in BeerFestDB::Dumper::Template;
please see that module's documentation for details.

=back

=head1 SEE ALSO

L<BeerFestDB::Dumper::Template>

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut
