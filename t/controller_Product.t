use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::Product' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/product',
            'Product index should succeed' );

$ua->get_ok('/product/view/1',
            'Product view should succeed' );

$ua->get_ok('/product/list/1/1',
            'Product list should succeed' );

$ua->get_ok('/product/grid/1/1',
            'Product grid should succeed' );

$ua->get_ok('/product/load_form',
            'Product load_form should succeed' );

$ua->get_ok('/product/list_by_company/1/1',
            'Product list_by_company should succeed' );

$ua->get_ok('/product/list_by_festival/1/2',
            'Product list_by_festival should succeed' );

$ua->get_ok('/product/list_by_order_batch/1/1',
            'Product list_by_order_batch should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/product/submit', 'Product submit should succeed' );
#$ua->get_ok('/product/delete', 'Product delete should succeed' );
#$ua->get_ok('/product/delete_from_stillage', 'Product delete_from_stillage should succeed' );

done_testing();
