use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::Festival' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/festival',
            'Festival index should succeed' );

$ua->get_ok('/festival/view/1',
            'Festival view should succeed' );

$ua->get_ok('/festival/list/1/1',
            'Festival list should succeed' );

$ua->get_ok('/festival/grid/1/1',
            'Festival grid should succeed' );

$ua->get_ok('/festival/load_form',
            'Festival load_form should succeed' );

$ua->get_ok('/festival/status/1',
            'Festival status should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/festival/submit', 'Festival submit should succeed' );
#$ua->get_ok('/festival/delete', 'Festival delete should succeed' );

done_testing();
