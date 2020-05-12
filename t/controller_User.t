use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::User' }

my $ua = authenticated_user("admin", "admin");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/user/view/1',
            'User view should succeed' );

$ua->get_ok('/user/list',
            'User list should succeed' );

$ua->get_ok('/user/grid',
            'User grid should succeed' );

$ua->get_ok('/user/load_form',
            'User load_form should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/user/submit', 'User submit should succeed' );
#$ua->get_ok('/user/delete', 'User delete should succeed' );
#$ua->get_ok('/user/modify', 'User modify should succeed' );

done_testing();
