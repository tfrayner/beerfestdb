#!/usr/bin/env perl
#
# $Id$

use strict;
use warnings;

use Getopt::Long;
use Config::YAML;
use Pod::Usage;

use BeerFestDB::ORM;
use BeerFestDB::Dumper::OODoc;

sub parse_args {

    my ( $conffile, $outfile, $want_help );

    GetOptions(
        "c|config=s"   => \$conffile,
        "f|filename=s" => \$outfile,
        "h|help"       => \$want_help,
    );

    if ($want_help) {
        pod2usage(
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 1,
        );
    }

    unless ( $conffile && $outfile ) {
        pod2usage(
            -message => qq{Please see "$0 -h" for further help notes.},
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 0,
        );
    }

    my $config = Config::YAML->new( config => $conffile );

    return( $outfile, $config );
}

########
# MAIN #
########

my ( $outfile, $config ) = parse_args();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $dumper = BeerFestDB::Dumper::OODoc->new(
    database => $schema,
    filename => $outfile,
);

$dumper->dump();

__END__

=head1 NAME

oodoc_dump.pl

=head1 SYNOPSIS

 oodoc_dump.pl -c <config file> -f <output file>

=head1 DESCRIPTION

This script can be used to dump out a defined set of information for
the beers for a given festival into OpenOffice ODF format.

=head2 OPTIONS

=over 2

=item -f

The output file to create. If the file already exists then new
information will be appended to it.

=item -c

The main BeerFestDB web config file.

=back

=head1 SEE ALSO

L<BeerFestDB::Dumper::OODoc>

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

Probably.

=cut
