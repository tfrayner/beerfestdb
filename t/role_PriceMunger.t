use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(schema);

BEGIN { use_ok 'BeerFestDB::Role::PriceMunger' }

# Minimal consumer.
{
    package TestPriceMunger;
    use Moose;
    with 'BeerFestDB::Role::PriceMunger';
}

my $db  = schema();
my $gbp = $db->resultset('Currency')->find({ currency_code => 'GBP' });

ok( $gbp, 'GBP currency fixture exists in test database' );

my $munger = TestPriceMunger->new( _default_currency => $gbp );

# -----------------------------------------------------------------------
# default_currency
# -----------------------------------------------------------------------

is( $munger->default_currency()->currency_code(), 'GBP',
    'default_currency: returns the set currency' );

# -----------------------------------------------------------------------
# parse_price — GBP has exponent 2, so multiply by 100
# -----------------------------------------------------------------------

is( $munger->parse_price(3.50),  350, 'parse_price: £3.50 => 350 pence' );
is( $munger->parse_price(0),       0, 'parse_price: £0 => 0 pence' );
is( $munger->parse_price(1),     100, 'parse_price: £1 => 100 pence' );
is( $munger->parse_price(10.99), 1099,'parse_price: £10.99 => 1099 pence' );

# Explicit currency argument overrides default.
is( $munger->parse_price(2.50, $gbp), 250,
    'parse_price: explicit currency argument accepted' );

# -----------------------------------------------------------------------
# format_price — GBP format '#,###,###,###,##0.00', exponent 2
# -----------------------------------------------------------------------

my $formatted = $munger->format_price(350, $gbp);
like( $formatted, qr/3\.50/, 'format_price: 350 pence formats to include 3.50' );

my $zero = $munger->format_price(0, $gbp);
like( $zero, qr/0\.00/, 'format_price: 0 pence formats to include 0.00' );

is( $munger->format_price(undef), undef,
    'format_price: undef input returns undef' );

done_testing();
