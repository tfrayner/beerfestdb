use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::FestivalProduct' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/festivalproduct',
            'FestivalProduct index should succeed' );

$ua->get_ok('/festivalproduct/view/1',
            'FestivalProduct view should succeed' );

$ua->get_ok('/festivalproduct/list/1/1',
            'FestivalProduct list should succeed' );

$ua->get_ok('/festivalproduct/grid/1/1',
            'FestivalProduct grid should succeed' );

$ua->get_ok('/festivalproduct/load_form',
            'FestivalProduct load_form should succeed' );

$ua->get_ok('/festivalproduct/list_by_product/1',
            'FestivalProduct list_by_product should succeed' );

$ua->get_ok('/festivalproduct/list_by_company/1',
            'FestivalProduct list_by_company should succeed' );

$ua->get_ok('/festivalproduct/list_status/1/1',
            'FestivalProduct list_status should succeed' );

# Deprecated; not even sure if this is currently functional.
#$ua->get_ok('/festivalproduct/html_status_list/1/1',
#            'FestivalProduct html_status_list should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/festivalproduct/submit', 'FestivalProduct submit should succeed' );
#$ua->get_ok('/festivalproduct/delete', 'FestivalProduct delete should succeed' );

done_testing();
