#
# This file is part of BeerFestDB, a beer festival product management
# system.
#
# Copyright (C) 2010-2026 Tim F. Rayner
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More;
use File::Find;

# Set the db config, but note that we're not initiating the db itself.
$ENV{BEERFESTDB_WEB_CONFIG} = 't/test_beerfestdb_web_submit.yml';

# Collect all .pl scripts under script/ and util/, excluding Makefile.PL.
my @scripts;
find(
    sub {
        return unless /\.pl$/;
        return if /^generate_orm\.pl$/; # code generating script, not used in production.
        push @scripts, $File::Find::name;
    },
    qw( script util ),
);

plan skip_all => 'No .pl scripts found' unless @scripts;
plan tests => scalar @scripts;

for my $script ( sort @scripts ) {
    my $out = `$^X -Ilib -c "$script" 2>&1`;
    ok( $? == 0, "$script compiles" )
        or diag $out;
}
