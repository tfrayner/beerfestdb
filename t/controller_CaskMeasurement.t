use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::CaskMeasurement' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/caskmeasurement/view/1',
            'CaskMeasurement view should succeed' );

$ua->get_ok('/caskmeasurement/load_form',
            'CaskMeasurement load_form should succeed' );

$ua->get_ok('/caskmeasurement/list/1/1',
            'CaskMeasurement list should succeed' );

$ua->get_ok('/caskmeasurement/list_by_cask/1',
            'CaskMeasurement list_by_cask should succeed' );

$ua->get_ok('/caskmeasurement/grid/1/1',
            'CaskMeasurement grid should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/caskmeasurement/submit', 'Caskmeasurement submit should succeed' );
#$ua->get_ok('/caskmeasurement/delete', 'CaskMeasurement delete should succeed' );

done_testing();
