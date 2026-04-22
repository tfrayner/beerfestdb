use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempfile);

use lib 't/lib';
use TestFestivalDB qw(schema);

BEGIN { use_ok 'BeerFestDB::Loader' }

my $db = schema();

# -----------------------------------------------------------------------
# Instantiation
# -----------------------------------------------------------------------

# Loader requires csv_file; use a minimal valid file.
my ( $fh_tmp, $tmpfile ) = tempfile( SUFFIX => '.tsv', UNLINK => 1 );
print $fh_tmp "brewery_name\tbrewery_loc_desc\n";
close $fh_tmp;

my $loader = BeerFestDB::Loader->new(
    database  => $db,
    csv_file  => $tmpfile,
    protected => [],           # allow all creates for tests
);
ok( $loader, 'BeerFestDB::Loader instantiates successfully' );
isa_ok( $loader, 'BeerFestDB::Loader' );

# -----------------------------------------------------------------------
# value_is_acceptable
# -----------------------------------------------------------------------

ok(  $loader->value_is_acceptable( 'hello' ),   'value_is_acceptable: normal string is acceptable' );
ok(  $loader->value_is_acceptable( '0' ),        'value_is_acceptable: "0" is acceptable' );
ok( !$loader->value_is_acceptable( undef ),      'value_is_acceptable: undef is not acceptable' );
ok( !$loader->value_is_acceptable( '' ),         'value_is_acceptable: empty string is not acceptable' );
ok( !$loader->value_is_acceptable( '?' ),        'value_is_acceptable: single ? is not acceptable' );
ok( !$loader->value_is_acceptable( '????' ),     'value_is_acceptable: multiple ? is not acceptable' );
ok(  $loader->value_is_acceptable( '? hello' ),  'value_is_acceptable: ? with other chars is acceptable' );

# -----------------------------------------------------------------------
# add_protection_error
# -----------------------------------------------------------------------

is( $loader->_error_count(), 0, 'Initial error count is zero' );

$loader->add_protection_error( { name => 'TestBrewer' }, 'Company' );

is( $loader->_error_count(), 1, 'add_protection_error increments error count' );
like( $loader->_error_report(), qr/Protection error \(Company\)/,
      'add_protection_error populates error report' );

# -----------------------------------------------------------------------
# load() — loads producers.csv (brewery_name + brewery_loc_desc only)
# -----------------------------------------------------------------------

my ( $fh_prod, $prod_file ) = tempfile( SUFFIX => '.tsv', UNLINK => 1 );
print $fh_prod qq{"brewery_name"\t"brewery_loc_desc"\n};
print $fh_prod qq{"Acme Test Brewery"\t"Cambridgeshire"\n};
print $fh_prod qq{"Another Test Brewery"\t"Norfolk"\n};
close $fh_prod;

my $load_db = schema();    # fresh schema against testing.db
my $loader2 = BeerFestDB::Loader->new(
    database  => $load_db,
    csv_file  => $prod_file,
    protected => [],
);

lives_ok { $loader2->load() } 'load() completes without dying for a simple producers file';

# Verify the companies were actually created (or already existed).
my @companies = $load_db->resultset('Company')->search({ name => 'Acme Test Brewery' })->all();
is( scalar @companies, 1, 'Loader created the expected Company record' );

done_testing();
