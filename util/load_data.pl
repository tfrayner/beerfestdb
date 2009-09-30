#!/usr/bin/env perl
#
# $Id$

use strict;
use warnings;

use Getopt::Long;
use Readonly;

use BeerFestDB::Loader;
use BeerFestDB::Common qw(connect_db);

Readonly my $VERSION => '0.3';

########
# SUBS #
########

sub parse_opts {

    my ( $input, $want_version, $want_help );

    GetOptions(
	"i|input=s" => \$input,
	"v|version" => \$want_version,
	"h|help"    => \$want_help,
    );

    if ( $want_version ) {
	print "This is load_data.pl v$VERSION\n";
	exit 255;
    }

    if ( $want_help || ! $input ) {
	print <<"USAGE";
   Usage: load_data.pl -i <input file name>
USAGE

	exit 255;
    }

    return $input;
}

########
# MAIN #
########

my $input  = parse_opts();
my $schema = connect_db();
my $loader = BeerFestDB::Loader->new({
    schema => $schema,
});

$loader->load( $input );
