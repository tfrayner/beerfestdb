use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }

ok( request('/')->is_success, 'Top-level request should succeed' );
is( request('/login')->code, '403', 'Empty login request should 403' );
is( request('/default')->code, '404', 'Default request should 404' );
ok( request('/index')->is_error, 'Index request should fail' );

my $ua1 = authenticated_user("admin", "admin");
my $ua2 = authenticated_user("cellar", "cellar");

$_->get_ok("https://localhost/", "Check redirect of base URL") for $ua1, $ua2;
$_->title_is("Welcome to BeerFestDB", "Check for login title") for $ua1, $ua2;

# Test logout and json_logout on a dedicated authenticated session
my $ua3 = authenticated_user("admin", "admin");
$ua3->get_ok('/json_logout', 'json_logout should succeed for authenticated user');

my $ua4 = authenticated_user("cellar", "cellar");
$ua4->get_ok('/logout', 'logout should succeed for authenticated user');

done_testing();

