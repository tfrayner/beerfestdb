use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::ProductOrder' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/productorder/list/1/1',
            'ProductOrder list should succeed' );

$ua->get_ok('/productorder/grid/1/1',
            'ProductOrder grid should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/productorder/submit', 'ProductOrder submit should succeed' );
#$ua->get_ok('/productorder/delete', 'ProductOrder delete should succeed' );

done_testing();
