use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::BayPosition' }

my $ua = authenticated_user("admin", "admin");

$ua->get_ok('/bayposition/list', 'BayPosition list should succeed' );

done_testing();
