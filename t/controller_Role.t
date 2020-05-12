use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::Role' }

my $ua = authenticated_user("admin", "admin");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/role/list',
            'Role list should succeed' );

done_testing();
