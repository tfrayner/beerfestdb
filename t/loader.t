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

# -----------------------------------------------------------------------
# _coerce_headings — characteristic column heading variants
# -----------------------------------------------------------------------

my $canon = $loader->_coerce_headings([ 'characteristic_type', 'characteristic_value' ]);
ok( $canon->[0] != 0, '_coerce_headings: "characteristic_type" is recognised (not UNKNOWN_COLUMN)' );
ok( $canon->[1] != 0, '_coerce_headings: "characteristic_value" is recognised (not UNKNOWN_COLUMN)' );
isnt( $canon->[0], $canon->[1], '_coerce_headings: type and value map to distinct constants' );

my $prefixed = $loader->_coerce_headings([ 'product_characteristic_type', 'product_characteristic_value' ]);
is( $prefixed->[0], $canon->[0],
    '_coerce_headings: "product_characteristic_type" maps to same constant as "characteristic_type"' );
is( $prefixed->[1], $canon->[1],
    '_coerce_headings: "product_characteristic_value" maps to same constant as "characteristic_value"' );

my $spaced = $loader->_coerce_headings([ 'characteristic type', 'characteristic-value' ]);
is( $spaced->[0], $canon->[0],
    '_coerce_headings: space-separated "characteristic type" maps correctly' );
is( $spaced->[1], $canon->[1],
    '_coerce_headings: hyphen-separated "characteristic-value" maps correctly' );

# -----------------------------------------------------------------------
# load() — ProductCharacteristic loading
# -----------------------------------------------------------------------

# Helper: build a TSV tempfile from headers + rows.
sub _make_tsv {
    my ( @rows ) = @_;
    my ( $fh, $file ) = tempfile( SUFFIX => '.tsv', UNLINK => 1 );
    print $fh join( "\t", @$_ ) . "\n" for @rows;
    close $fh;
    return $file;
}

# The shared test DB (t/testing.db) has:
#   ProductCharacteristicType id=1, category='foreign beer', description='TestCharacteristic'
#   Product id=1, name='TestBeer', company='TestBrewer', category='foreign beer'

my @char_headers = qw( brewery_name product_name product_category
                        characteristic_type characteristic_value );

# 1. Both columns blank — no ProductCharacteristic created.
my $pc_blank_both = _make_tsv(
    \@char_headers,
    [ 'TestBrewer', 'TestBeer', 'foreign beer', '', '' ],
);
my $loader_blank_both = BeerFestDB::Loader->new(
    database  => $db,
    csv_file  => $pc_blank_both,
    protected => [],
);
lives_ok { $loader_blank_both->load() }
    'characteristic load: blank type+value does not die';
is( $db->resultset('ProductCharacteristic')->count(), 0,
    'No ProductCharacteristic created when both columns are blank' );

# 2. Value blank, type present — no ProductCharacteristic created.
my $pc_blank_val = _make_tsv(
    \@char_headers,
    [ 'TestBrewer', 'TestBeer', 'foreign beer', 'TestCharacteristic', '' ],
);
my $loader_blank_val = BeerFestDB::Loader->new(
    database  => $db,
    csv_file  => $pc_blank_val,
    protected => [],
);
lives_ok { $loader_blank_val->load() }
    'characteristic load: blank value (type present) does not die';
is( $db->resultset('ProductCharacteristic')->count(), 0,
    'No ProductCharacteristic created when characteristic_value is blank' );

# 3. Valid type + value — ProductCharacteristic created with correct fields.
my $pc_valid = _make_tsv(
    \@char_headers,
    [ 'TestBrewer', 'TestBeer', 'foreign beer', 'TestCharacteristic', 'High' ],
);
my $loader_valid = BeerFestDB::Loader->new(
    database  => $db,
    csv_file  => $pc_valid,
    protected => [],
);
lives_ok { $loader_valid->load() }
    'characteristic load: valid type+value does not die';
is( $db->resultset('ProductCharacteristic')->count(), 1,
    'Exactly one ProductCharacteristic created for a valid row' );

my $pchar_rec = $db->resultset('ProductCharacteristic')->first();
is( $pchar_rec->value,                                 'High', 'ProductCharacteristic has correct value' );
is( $pchar_rec->get_column('product_id'),              1,      'ProductCharacteristic linked to correct product' );
is( $pchar_rec->get_column('product_characteristic_type_id'), 1,
    'ProductCharacteristic linked to correct type' );

# 4. Loading the same row again is idempotent (find_or_create).
my $loader_again = BeerFestDB::Loader->new(
    database  => $db,
    csv_file  => $pc_valid,
    protected => [],
);
lives_ok { $loader_again->load() }
    'characteristic load: re-loading the same row does not die';
is( $db->resultset('ProductCharacteristic')->count(), 1,
    'Re-loading the same row does not create a duplicate' );

# 5. The "product_characteristic_type/value" header prefix variants are recognised.
my $pc_prefixed = _make_tsv(
    [ 'brewery_name', 'product_name', 'product_category',
      'product_characteristic_type', 'product_characteristic_value' ],
    [ 'TestBrewer', 'TestBeer', 'foreign beer', 'TestCharacteristic', 'High' ],
);
my $loader_prefixed = BeerFestDB::Loader->new(
    database  => $db,
    csv_file  => $pc_prefixed,
    protected => [],
);
lives_ok { $loader_prefixed->load() }
    'characteristic load: "product_characteristic_type/value" header variants do not die';
is( $db->resultset('ProductCharacteristic')->count(), 1,
    'No duplicate created when loading with product_characteristic_type/value headers' );

done_testing();
