#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2020 Tim F. Rayner
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
#
# $Id$

package TestFestivalDB;

use 5.008;

use strict; 
use warnings;

use Carp;

use Test::More;
use File::Copy qw(copy);
use BeerFestDB::ORM;
use DBI;

require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(schema authenticated_user);

my $schema;

BEGIN {

    $ENV{BEERFESTDB_WEB_CONFIG} = 't/test_beerfestdb_web.yml';

    my $db = "t/pristine_testing.db";
    my $dsn = "DBI:SQLite:$db";

    $schema = BeerFestDB::ORM->connect($dsn);

    if ( ! -e $db ) {

        $schema->deploy();

        # Initialise our starting vocabularies.
        my $dbh = DBI->connect($dsn);
        open(my $sql, "<", "db/initialise_vocabs.sql") or die($!);
        {
            local $/ = ";\n";
            foreach my $line (<$sql>) {
                $dbh->do($line);
            }
        }
        $dbh->disconnect();

        # Create some fixture objects to test against.
        $schema->resultset("Festival")
            ->find_or_create({festival_id => 1,
                              year => 2020,
                              name => "TestFestival"});

        $schema->resultset("Company")
            ->find_or_create({company_id => 1,
                              company_region_id => 5, # Cambridgeshire
                              name => "TestBrewer"});

        $schema->resultset("Contact")
            ->find_or_create({contact_id => 1,
                              company_id => 1,
                              contact_type_id => 1, # Customer service
                              last_name => "TestContact"});

        $schema->resultset("Product")
            ->find_or_create({product_id => 1,
                              company_id => 1,
                              product_category_id => 2,
                              name => "TestBeer"});

        $schema->resultset("FestivalProduct")
            ->find_or_create({festival_product_id => 1,
                              product_id => 1,
                              festival_id => 1,
                              sale_volume_id => 1,
                              sale_currency_id => 1});

        $schema->resultset("Gyle")
            ->find_or_create({gyle_id => 1,
                              company_id => 1,
                              festival_product_id => 1,
                              internal_reference => 1});

        $schema->resultset("StillageLocation")
            ->find_or_create({stillage_location_id => 1,
                              festival_id => 1,
                              description => "TestStillage"});

        $schema->resultset("CaskManagement")
            ->find_or_create({cask_management_id => 1,
                              festival_id => 1,
                              container_size_id => 1,
                              currency_id => 1,
                              stillage_location_id => 1,
                              cellar_reference => 1});

        $schema->resultset("Cask")
            ->find_or_create({cask_id => 1,
                              gyle_id => 1,
                              cask_management_id => 1});

        $schema->resultset("MeasurementBatch")
            ->find_or_create({measurement_batch_id => 1,
                              festival_id => 1,
                              measurement_time => '1970-01-01 01:00:00'});

        $schema->resultset("CaskMeasurement")
            ->find_or_create({cask_measurement_id => 1,
                              cask_id => 1,
                              container_measure_id => 1,
                              measurement_batch_id => 1,
                              volume => 3.0});

        $schema->resultset("OrderBatch")
            ->find_or_create({order_batch_id => 1,
                              festival_id => 1,
                              description => "TestOrderBatch"});

    }

    # Refresh from pristine_testing.db every time.
    copy( $db, "t/testing.db" )
};

sub schema { $schema }

sub authenticated_user { # Worth 2 tests

    my ( $user, $pass ) = @_;

    use ok "Test::WWW::Mechanize::Catalyst" => "BeerFestDB::Web";

    my $ua = Test::WWW::Mechanize::Catalyst->new;

    $ua->get_ok(
        '/login?data={"username":"'.$user.'","password":"'.$pass.'"}',
        "Login $user user"
    );

    return($ua)
}

1;
