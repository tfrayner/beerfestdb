use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::Telephone' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/telephone/list_by_contact/1',
            'Telephone list_by_contact should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/telephone/submit', 'Telephone submit should succeed' );
#$ua->get_ok('/telephone/delete', 'Telephone delete should succeed' );

done_testing();
