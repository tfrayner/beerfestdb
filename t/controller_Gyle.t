use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::Gyle' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/gyle',
            'Gyle index should succeed' );

$ua->get_ok('/gyle/list_by_festival_product/1',
            'Gyle list_by_festival_product should succeed' );

$ua->get_ok('/gyle/list_by_festival/1',
            'Gyle list_by_festival should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/gyle/submit', 'Gyle submit should succeed' );
#$ua->get_ok('/gyle/delete', 'Gyle delete should succeed' );

done_testing();
