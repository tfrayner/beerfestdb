#!/usr/bin/env perl
#
# $Id$

use strict;
use warnings;

use Getopt::Long;
use Config::YAML;
use Pod::Usage;

use BeerFestDB::ORM;
use BeerFestDB::Dumper::Template;

sub parse_args {

    my ( $conffile, $templatefile, $logofile, $all_casks, $want_help );

    GetOptions(
        "c|config=s"   => \$conffile,
        "t|template=s" => \$templatefile,
        "l|logo=s"     => \$logofile,
        "a|all"        => \$all_casks,
        "h|help"       => \$want_help,
    );

    if ($want_help) {
        pod2usage(
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 1,
        );
    }

    unless ( $conffile && $templatefile ) {
        pod2usage(
            -message => qq{Please see "$0 -h" for further help notes.},
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 0,
        );
    }

    my $config = Config::YAML->new( config => $conffile );

    return( $templatefile, $logofile, $config, $all_casks );
}

########
# MAIN #
########

my ( $templatefile, $logofile, $config, $all_casks ) = parse_args();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $dumper = BeerFestDB::Dumper::Template->new(
    database => $schema,
    template => $templatefile,
    logos    => [ $logofile ],
    all_casks => $all_casks,
);

$dumper->dump();

__END__

=head1 NAME

format_beers.pl

=head1 SYNOPSIS

 format_beers.pl -c <config file> -t <template file> -l <logo file>

=head1 DESCRIPTION

This is a general-purpose script used to dump information on beers
held in the BeerFestDB database into a variety of file formats. It
works by taking a Template Toolkit-style template file, and applying
it to the information held in the database. See
L<BeerFestDB::Dumper::Template> for details on how variables are
passed into the template.

=head2 OPTIONS

=over 2

=item -c

The main BeerFestDB web config file.

=item -t

The Template Toolkit file to apply to the data.

=item -l

An optional logo file, the name of which will be passed into the
template file as the first element of the "logos" array.

=item -a

Indicate that one record per cask should be formatted. The default is
to write one record per product.

=back

=head1 SEE ALSO

L<BeerFestDB::Dumper::Template>

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
