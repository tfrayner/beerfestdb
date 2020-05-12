use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::Company' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/company/view/1',
            'Company view should succeed' );

$ua->get_ok('/company/load_form',
            'Company load_form should succeed' );

$ua->get_ok('/company/list',
            'Company list should succeed' );

$ua->get_ok('/company/grid',
            'Company grid should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/company/submit', 'Company submit should succeed' );
#$ua->get_ok('/company/delete', 'Company delete should succeed' );

done_testing();
