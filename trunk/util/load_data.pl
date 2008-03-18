#!/usr/bin/env perl
#
# $Id$

use strict;
use warnings;

use Getopt::Long;
use Readonly;

use BeerFestDB::Loader;
use BeerFestDB::ORM;
use BeerFestDB::Config qw($CONFIG);

Readonly my $VERSION => '0.2';

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

sub connect_db {
    
    my $dsn = sprintf(
	"DBI:mysql:%s:%s:%s",
	$CONFIG->get_database(),
	$CONFIG->get_host(),
	$CONFIG->get_port(),
    );
    my $schema = BeerFestDB::ORM->connect(
	$dsn,
	$CONFIG->get_user(),
	$CONFIG->get_pass(),
	{ PrintError => 0, RaiseError => 1, AutoCommit => 1 },
    );

    return $schema;
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
