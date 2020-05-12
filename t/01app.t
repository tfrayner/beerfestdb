use strict;
use warnings;
use Test::More tests => 12;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }

ok( request('/')->is_success, 'Top-level request should succeed' );
is( request('/login')->code, '403', 'Empty login request should 403' );
is( request('/default')->code, '404', 'Default request should 404' );
ok( request('/index')->is_error, 'Index request should fail' );

my $ua1 = authenticated_user("admin", "admin");
my $ua2 = authenticated_user("cellar", "cellar");

$_->get_ok("http://localhost/", "Check redirect of base URL") for $ua1, $ua2;
$_->title_is("Welcome to BeerFestDB", "Check for login title") for $ua1, $ua2;

