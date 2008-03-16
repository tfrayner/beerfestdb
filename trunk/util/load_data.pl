#!/usr/bin/env perl
#
# $Id$

use strict;
use warnings;

use Getopt::Long;
use Text::CSV_XS;
use Readonly;

use BeerFestDB::ORM;
use BeerFestDB::Config qw($CONFIG);

Readonly my $VERSION => '0.1';

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

sub get_schema {
    
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

sub get_csv_parser {

    my $csv_parser = Text::CSV_XS->new(
        {   sep_char    => qq{\t},
            quote_char  => qq{"},                   # default
            escape_char => qq{"},                   # default
            binary      => 1,
	    allow_loose_quotes => 1,
        }
    );

    return $csv_parser;
}

sub load_data {

    my ( $datahash, $schema ) = @_;

    # Each of these calls defines the column to be used from the input
    # file.
    my $festival = load_festival(
	{
	    year        => $datahash->{'festival_year'},
	    description => $datahash->{'festival_description'},
	},
	$schema,
    );
    my $bar = load_bar(
	{
	    description => $datahash->{'bar_description'},
	},
	$schema,
    );

    # FIXME no addresses at this point.
    my $brewer = load_company(
	{
	    name         => $datahash->{'brewer_name'},
	    loc_desc     => $datahash->{'brewer_loc_desc'},
	    year_founded => $datahash->{'brewer_year_founded'},
	    comment      => $datahash->{'brewer_comment'},
	},
	$schema,
    );
    my $beer = load_beer(
	{
	    name         => $datahash->{'beer_name'},
	    style        => $datahash->{'beer_style'},
	    description  => $datahash->{'beer_description'},
	    comment      => $datahash->{'beer_comment'},
	},
	$schema,
    );
    my $gyle = load_gyle(
	{
	    brewery_number => $datahash->{'gyle_brewery_number'},
	    brewer         => $brewer,
	    beer           => $beer,
	    abv            => $datahash->{'gyle_abv'},
	    pint_price     => $datahash->{'gyle_pint_price'},
	    comment        => $datahash->{'gyle_comment'},
	},
	$schema,
    );
    my $distributor = load_company(
	{
	    name         => $datahash->{'distributor_name'},
	    loc_desc     => $datahash->{'distributor_loc_desc'},
	    year_founded => $datahash->{'distributor_year_founded'},
	    comment      => $datahash->{'distributor_comment'},
	},
	$schema,
    );
    my $cask = load_cask(
	{
	    brewer      => $brewer,
	    beer        => $beer,
	    gyle        => $gyle,
	    distributor => $distributor,
	    festival    => $festival,
	    size        => $datahash->{'cask_size'},
	    cask_price  => $datahash->{'cask_price'},
	    bar         => $bar,
	    comment     => $datahash->{'cask_comment'},
	},
	$schema,
    );
    my $cask_measurement = load_cask_measurement(
	{
	    cask    => $cask,
	    date    => $datahash->{'cask_measurement_date'},
	    volume  => $datahash->{'cask_measurement_volume'},
	    comment => $datahash->{'cask_measurement_comment'},
	},
	$schema,
    );
}

sub load_festival {

    my ( $args, $schema ) = @_;

    my $festival;
    if ( defined $args->{'year'} ) {

	$festival = $schema->resultset('Festival')->find_or_create({
	    year => $args->{'year'},
	});

	if ( defined $args->{'description'} ) {
	    $festival->set_column('description' => $args->{'description'});
	}

	$festival->update();
    }

    return $festival;
}

sub load_bar {

    my ( $args, $schema ) = @_;

    my $bar;
    if ( defined $args->{'description'} ) {
	$bar = $schema->resultset('Bar')->find_or_create({
	    description => $args->{'description'},
	});
    }

    return $bar;
}

sub load_company {

    my ( $args, $schema ) = @_;

    my $company;
    if ( defined $args->{'name'} ) {

	$company = $schema->resultset('Company')->find_or_create({
	    name => $args->{'name'},
	});

	if ( defined $args->{'loc_desc'} ) {
	    $company->set_column('loc_desc' => $args->{'loc_desc'});
	}
	if ( defined $args->{'year_founded'} ) {
	    $company->set_column('year_founded' => $args->{'year_founded'});
	}
	if ( defined $args->{'comment'} ) {
	    $company->set_column('comment' => $args->{'comment'});
	}

	$company->update();
    }

    return $company;
}

sub load_beer {

    my ( $args, $schema ) = @_;

    my $beer;
    if ( defined $args->{'name'} ) {

	$beer = $schema->resultset('Beer')->find_or_create({
	    name => $args->{'name'},
	});

	if ( defined $args->{'style'} ) {
	    $beer->set_column('style' => $args->{'style'});
	}
	if ( defined $args->{'description'} ) {
	    $beer->set_column('description' => $args->{'description'});
	}
	if ( defined $args->{'comment'} ) {
	    $beer->set_column('comment' => $args->{'comment'});
	}

	$beer->update();
    }

    return $beer;
}

sub load_gyle {

    my ( $args, $schema ) = @_;

    my $gyle;
    if ( defined $args->{'beer'} ) {

	$gyle = $schema->resultset('Gyle')->find_or_create({
	    beer       => $args->{'beer'},
	    brewer     => $args->{'brewer'},
	    abv        => $args->{'abv'},
	});

	if ( defined $args->{'pint_price'} ) {
	    $gyle->set_column('pint_price' => $args->{'pint_price'});
	}
	if ( defined $args->{'brewery_number'} ) {
	    $gyle->set_column('brewery_number' => $args->{'brewery_number'});
	}
	if ( defined $args->{'comment'} ) {
	    $gyle->set_column('comment' => $args->{'comment'});
	}

	$gyle->update();
    }

    return $gyle;
}

sub load_cask {

    my ( $args, $schema ) = @_;

    my $cask;
    if ( defined $args->{'beer'} ) {

	$cask = $schema->resultset('Cask')->find_or_create({
	    beer        => $args->{'beer'},
	    brewer      => $args->{'brewer'},
	    gyle        => $args->{'gyle'},
	    beer        => $args->{'beer'},
	    distributor => $args->{'distributor'},
	    festival    => $args->{'festival'},
	    bar         => $args->{'bar'},
	});

	if ( defined $args->{'size'} ) {
	    $cask->set_column('size' => $args->{'size'});
	}
	if ( defined $args->{'cask_price'} ) {
	    $cask->set_column('cask_price' => $args->{'cask_price'});
	}
	if ( defined $args->{'comment'} ) {
	    $cask->set_column('comment' => $args->{'comment'});
	}

	$cask->update();
    }

    return $cask;
}

sub load_cask_measurement {

    my ( $args, $schema ) = @_;

    my $cask_measurement;
    if ( defined $args->{'volume'} ) {

	$cask_measurement = $schema->resultset('CaskMeasurement')->find_or_create({
	    cask        => $args->{'cask'},
	    date        => $args->{'date'},
	    volume      => $args->{'volume'},
	});

	if ( defined $args->{'comment'} ) {
	    $cask_measurement->set_column('comment' => $args->{'comment'});
	}

	$cask_measurement->update();
    }

    return $cask_measurement;
}

########
# MAIN #
########

my $input      = parse_opts();
my $schema     = get_schema();
my $csv_parser = get_csv_parser();

open( my $input_fh, '<', $input )
    or die(qq{Error opening input file "$input": $!});

# Assume first line is the header, for now:
my $headings = $csv_parser->getline($input_fh);

while ( my $rowlist = $csv_parser->getline($input_fh) ) {
    my %datahash;
    @datahash{ map { lc $_ } @$headings } = @$rowlist;
    load_data( \%datahash, $schema );
}
