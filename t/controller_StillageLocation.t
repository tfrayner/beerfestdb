use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::StillageLocation' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/stillagelocation/list/1',
            'StillageLocation list should succeed' );

$ua->get_ok('/stillagelocation/grid/1',
            'StillageLocation grid should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/stillagelocation/submit', 'StillageLocation submit should succeed' );
#$ua->get_ok('/stillagelocation/delete', 'StillageLocation delete should succeed' );

done_testing();
