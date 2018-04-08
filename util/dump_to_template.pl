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

use String::Range::Expand;

sub parse_idstr {

    my ( $idstr ) = @_;

    $idstr =~ s/\s+//g;

    my @ids;

    # Uses String::Range::Expand. If we ever extend this to gyle IDs,
    # bear in mind this will need to support containing having
    # non-expandable hyphens (e.g. 'auto-generated').
    foreach my $range ( split /,/, $idstr ) {
        push @ids, expand_range("[$range]");
    }

    return \@ids;
}

sub parse_args {

    my ( $templatefile, $logofile, $objectlevel, $split, $outdir, $force,
         $filterstr, $idstr, $idfile, $skip_unpriced, $want_help );

    GetOptions(
        "t|template=s"      => \$templatefile,
        "l|logo=s"          => \$logofile,
        "o|objects=s"       => \$objectlevel,
        "h|help"            => \$want_help,
        "s|split-output"    => \$split,
        "d|output-dir=s"    => \$outdir,
        "f|force-overwrite" => \$force,
        "filters=s"         => \$filterstr,
        "cask-ids=s"        => \$idstr,
        "cask-ids-from=s"   => \$idfile,
        "skip-unpriced"     => \$skip_unpriced,
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

    my $cask_ids = [];
    if ( $idfile ) {
        open( my $idfh, '<', $idfile ) or die("Unable to open ID file: $!\n");
        while ( my $line = <$idfh> ) {
            $line =~ s/\A \s*(.*?)\s* \z/$1/xms;
            push @$cask_ids, $line;
        }
    }
    if ( $idstr ) {
        push @$cask_ids, @{ parse_idstr($idstr) };
    }

    return( $templatefile, $logofile, $config, $objectlevel, $outdir,
            $split, $force, $filters, $cask_ids, $skip_unpriced );
}

########
# MAIN #
########

my ( $templatefile, $logofile, $config, $objectlevel,
     $outdir, $split, $force, $filters, $cask_ids, $skip_unpriced ) = parse_args();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $dumper = BeerFestDB::Dumper::Template->new(
    database      => $schema,
    template      => $templatefile,
    logos         => [ $logofile ],
    dump_class    => $objectlevel,
    split_output  => $split,
    output_dir    => $outdir,
    overwrite     => $force,
    filters       => $filters,
    cask_ids      => $cask_ids,
    skip_unpriced => $skip_unpriced,
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

=item --cask-ids

A list of cask IDs (currently supported only for dump classes 'cask' and
'cask_management') to which the output will be restricted. This option
should be a string separating IDs with commas. ID ranges can be
specified using hyphens. Spaces may be included for clarity, but only
if the entire string is enclosed in quotes. For example:

 --cask-ids '34-56, 95-107, 134-299'

=item --cask-ids-from

Similar to the --cask-ids option, this takes the cask IDs to be used
from the specified file, which should contain one ID per row.

=back

=item --skip-unpriced

Omit items from the output where no price (or a zero price) has been
indicated.

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
