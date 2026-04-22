use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);
use TestGenericGrid qw(generic_grid_tests);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::CompanyRegion' }

my $ua = authenticated_user("admin", "admin");

generic_grid_tests("companyregion", "CompanyRegion", $ua);

$ua->get_ok('/companyregion/view/1',
            'CompanyRegion view should succeed' );

$ua->get_ok('/companyregion/load_form',
            'CompanyRegion load_form should succeed' );

done_testing();
