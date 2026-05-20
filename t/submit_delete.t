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

# Test all controller submit and delete actions in dependency order.
# Deploys a fresh empty database, creates one of each supported object
# via HTTP POST (in dependency order), then deletes them all in reverse
# order, tearing the whole structure down.

use strict;
use warnings;

use JSON;
use Test::More;

# $schema is set inside the BEGIN block below and used at runtime for
# direct DBIC operations (CaskManagement has no submit controller).
my $schema;

BEGIN {
    $ENV{BEERFESTDB_WEB_CONFIG} = 't/test_beerfestdb_web_submit.yml';

    require BeerFestDB::ORM;

    my $db  = 't/testing_submit.db';
    my $dsn = "DBI:SQLite:$db";

    unlink $db if -e $db;

    $schema = BeerFestDB::ORM->connect($dsn);
    $schema->deploy();

    # ------------------------------------------------------------------
    # Seed minimum vocabulary (no HTTP submit controllers for these).
    # ------------------------------------------------------------------

    $schema->resultset('ContainerMeasure')->create({
        container_measure_id => 1,
        litre_multiplier     => '4.54609188',
        description          => 'gallon',
        symbol               => 'gal',
    });

    $schema->resultset('DispenseMethod')->create({
        dispense_method_id => 1,
        description        => 'cask',
    });

    $schema->resultset('ContainerSize')->create({
        container_size_id    => 1,
        container_volume     => 9,
        container_measure_id => 1,
        description          => 'firkin',
        dispense_method_id   => 1,
    });

    $schema->resultset('Currency')->create({
        currency_id     => 1,
        currency_code   => 'GBP',
        currency_number => '826',
        currency_format => '%s',
        exponent        => 2,
        currency_symbol => 'GBP',
    });

    $schema->resultset('SaleVolume')->create({
        sale_volume_id       => 1,
        container_measure_id => 1,
        description          => 'pint',
        volume               => '0.57',
    });

    $schema->resultset('ProductCategory')->create({
        product_category_id => 1,
        description         => 'beer',
    });

    $schema->resultset('CompanyRegion')->create({
        company_region_id => 1,
        description       => 'TestRegion',
    });

    $schema->resultset('ContactType')->create({
        contact_type_id => 1,
        description     => 'TestContactType',
    });

    $schema->resultset('TelephoneType')->create({
        telephone_type_id => 1,
        description       => 'TestTelephoneType',
    });

    $schema->resultset('Country')->create({
        country_id        => 1,
        country_code_iso2 => 'GB',
        country_code_iso3 => 'GBR',
        country_code_num3 => '826',
        country_name      => 'United Kingdom',
    });

    # ------------------------------------------------------------------
    # Seed roles and the admin user needed for HTTP authentication.
    # ------------------------------------------------------------------

    $schema->resultset('Role')->create({ role_id => 1, rolename => 'admin' });
    $schema->resultset('Role')->create({ role_id => 2, rolename => 'user'  });

    # Password is the SSHA1 hash of 'admin' (same as pristine_testing.db).
    $schema->resultset('User')->create({
        username => 'admin',
        email    => 'admin@localhost',
        password => '{SSHA}phihZR8gSGUPNV0GYRRixWhlNS6rnO9q',
    });

    # Admin needs both 'admin' (controller-level checks) and 'user'
    # (ACL allow_access_if) roles, matching the pristine test DB.
    $schema->resultset('UserRole')->create({ user_id => 1, role_id => 1 });
    $schema->resultset('UserRole')->create({ user_id => 1, role_id => 2 });
}

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }

use_ok 'Test::WWW::Mechanize::Catalyst' => 'BeerFestDB::Web';

# ---------------------------------------------------------------------------
# Authenticate as admin
# ---------------------------------------------------------------------------

my $ua = Test::WWW::Mechanize::Catalyst->new;
$ua->get_ok(
    '/login?data={"username":"admin","password":"admin"}',
    'Login admin user',
);

# Every response includes X-CSRF-Token; capture it for inclusion in POSTs.
my $csrf_token = $ua->response->header('X-CSRF-Token');
ok( defined $csrf_token, 'Got CSRF token from login response' );

# ---------------------------------------------------------------------------
# Helper subroutines
# ---------------------------------------------------------------------------

# submit_ok: POST a JSON changes array, verify success, return ids arrayref.
sub submit_ok {
    my ( $ua, $path, $changes_aref, $desc ) = @_;
    $ua->post_ok(
        $path,
        { changes => encode_json($changes_aref), csrf_token => $csrf_token },
        $desc,
    );
    my $data = decode_json( $ua->content );
    ok( $data->{success}, "$desc: success" );
    return $data->{ids};
}

# delete_ok: POST a JSON array of IDs to delete, verify completion.
# Controllers signal deletion-complete by returning success=false.
sub delete_ok {
    my ( $ua, $path, $ids_aref, $desc ) = @_;
    $ua->post_ok(
        $path,
        { changes => encode_json($ids_aref), csrf_token => $csrf_token },
        $desc,
    );
    my $data = decode_json( $ua->content );
    ok( !$data->{success}, "$desc: complete" );
}

# ===========================================================================
# SUBMIT — create one of each object in dependency order
# ===========================================================================

# 1. Festival — no FK deps on submit-able tables.
my $festival_ids = submit_ok(
    $ua, '/festival/submit',
    [{ year => 2025, name => 'TestFestival', description => 'Test Festival' }],
    'Festival submit',
);
ok( defined $festival_ids && @$festival_ids, 'Festival: ids returned' );
my $festival_id = $festival_ids->[0];

# 2. Company — needs company_region_id (seeded).
my $company_ids = submit_ok(
    $ua, '/company/submit',
    [{ name => 'TestBrewery', company_region_id => 1 }],
    'Company submit',
);
ok( defined $company_ids && @$company_ids, 'Company: ids returned' );
my $company_id = $company_ids->[0];

# 3. Contact — needs company_id, contact_type_id (seeded).
my $contact_ids = submit_ok(
    $ua, '/contact/submit',
    [{ company_id => $company_id, contact_type_id => 1, last_name => 'TestContact' }],
    'Contact submit',
);
ok( defined $contact_ids && @$contact_ids, 'Contact: ids returned' );
my $contact_id = $contact_ids->[0];

# 4. Telephone — needs contact_id, telephone_type_id (seeded).
my $telephone_ids = submit_ok(
    $ua, '/telephone/submit',
    [{ contact_id => $contact_id, telephone_type_id => 1, local_number => '01234567890' }],
    'Telephone submit',
);
ok( defined $telephone_ids && @$telephone_ids, 'Telephone: ids returned' );
my $telephone_id = $telephone_ids->[0];

# 5. Product — needs company_id, product_category_id (seeded).
my $product_ids = submit_ok(
    $ua, '/product/submit',
    [{ company_id => $company_id, product_category_id => 1, name => 'TestBeer' }],
    'Product submit',
);
ok( defined $product_ids && @$product_ids, 'Product: ids returned' );
my $product_id = $product_ids->[0];

# 6. FestivalProduct — needs festival_id, product_id, sale_volume_id, sale_currency_id.
my $festival_product_ids = submit_ok(
    $ua, '/festivalproduct/submit',
    [{ festival_id      => $festival_id,
       product_id       => $product_id,
       sale_volume_id   => 1,
       sale_currency_id => 1 }],
    'FestivalProduct submit',
);
ok( defined $festival_product_ids && @$festival_product_ids, 'FestivalProduct: ids returned' );
my $festival_product_id = $festival_product_ids->[0];

# 7. OrderBatch — needs festival_id.
my $order_batch_ids = submit_ok(
    $ua, '/orderbatch/submit',
    [{ festival_id => $festival_id, description => 'TestOrderBatch' }],
    'OrderBatch submit',
);
ok( defined $order_batch_ids && @$order_batch_ids, 'OrderBatch: ids returned' );
my $order_batch_id = $order_batch_ids->[0];

# 8. StillageLocation — needs festival_id.
my $stillage_location_ids = submit_ok(
    $ua, '/stillagelocation/submit',
    [{ festival_id => $festival_id, description => 'TestStillage' }],
    'StillageLocation submit',
);
ok( defined $stillage_location_ids && @$stillage_location_ids, 'StillageLocation: ids returned' );
my $stillage_location_id = $stillage_location_ids->[0];

# 9. MeasurementBatch — needs festival_id; measurement_time is NOT NULL.
my $measurement_batch_ids = submit_ok(
    $ua, '/measurementbatch/submit',
    [{ festival_id      => $festival_id,
       measurement_time => '2025-01-01 01:00:00',
       description      => 'TestBatch' }],
    'MeasurementBatch submit',
);
ok( defined $measurement_batch_ids && @$measurement_batch_ids, 'MeasurementBatch: ids returned' );
my $measurement_batch_id = $measurement_batch_ids->[0];

# 10. ProductOrder — needs order_batch_id, product_id, distributor_company_id,
#     container_size_id (seeded), currency_id (seeded).
my $product_order_ids = submit_ok(
    $ua, '/productorder/submit',
    [{ order_batch_id         => $order_batch_id,
       product_id             => $product_id,
       distributor_company_id => $company_id,
       container_size_id      => 1,
       cask_count             => 1,
       currency_id            => 1 }],
    'ProductOrder submit',
);
ok( defined $product_order_ids && @$product_order_ids, 'ProductOrder: ids returned' );
my $product_order_id = $product_order_ids->[0];

# 11. Gyle — needs company_id, festival_product_id; int_reference (= internal_reference) is NOT NULL.
my $gyle_ids = submit_ok(
    $ua, '/gyle/submit',
    [{ company_id          => $company_id,
       festival_product_id => $festival_product_id,
       int_reference       => 'G001' }],
    'Gyle submit',
);
ok( defined $gyle_ids && @$gyle_ids, 'Gyle: ids returned' );
my $gyle_id = $gyle_ids->[0];

# 12. CaskManagement — no HTTP submit controller; create directly via DBIC.
#     cellar_reference is NOT NULL. product_order_id is left NULL so that
#     the Cask delete controller will auto-remove this row.
my $cask_management = $schema->resultset('CaskManagement')->create({
    festival_id       => $festival_id,
    container_size_id => 1,
    currency_id       => 1,
    cellar_reference  => 1,
});
my $cask_management_id = $cask_management->cask_management_id();
ok( $cask_management_id, 'CaskManagement: created directly via DBIC' );

# 13. Cask — needs gyle_id, cask_management_id.
my $cask_ids = submit_ok(
    $ua, '/cask/submit',
    [{ gyle_id => $gyle_id, cask_management_id => $cask_management_id }],
    'Cask submit',
);
ok( defined $cask_ids && @$cask_ids, 'Cask: ids returned' );
my $cask_id = $cask_ids->[0];

# 14. CaskMeasurement — special submit: does not return ids.
#     container_measure_id is set automatically from the cask's container_size.
submit_ok(
    $ua, '/caskmeasurement/submit',
    [{ cask_id              => $cask_id,
       measurement_batch_id => $measurement_batch_id,
       volume               => 9.0 }],
    'CaskMeasurement submit',
);
my $cask_measurement = $schema->resultset('CaskMeasurement')
    ->find({ cask_id => $cask_id, measurement_batch_id => $measurement_batch_id });
ok( defined $cask_measurement, 'CaskMeasurement: row created in DB' );
my $cask_measurement_id = $cask_measurement
    ? $cask_measurement->cask_measurement_id()
    : undef;

# 15. User — admin creates a second user with the 'user' role (role_id=2).
my $user_ids = submit_ok(
    $ua, '/user/submit',
    [{ username => 'testuser',
       email    => 'testuser@localhost',
       password => 'testpass',
       name     => 'Test User',
       roles    => '2' }],
    'User submit',
);
ok( defined $user_ids && @$user_ids, 'User: ids returned' );
my $test_user_id = $user_ids->[0];

# ===========================================================================
# DELETE — remove all objects in reverse dependency order
# ===========================================================================

# 15. User (test user only; admin user is left in place).
delete_ok( $ua, '/user/delete',             [$test_user_id],           'User delete' );

# 14. CaskMeasurement — must precede Cask deletion.
delete_ok( $ua, '/caskmeasurement/delete',  [$cask_measurement_id],    'CaskMeasurement delete' );

# 13. Cask — Cask controller auto-removes the associated CaskManagement
#     row because its product_order_id is NULL.
delete_ok( $ua, '/cask/delete',             [$cask_id],                'Cask delete' );

# 11. Gyle
delete_ok( $ua, '/gyle/delete',             [$gyle_id],                'Gyle delete' );

# 10. ProductOrder
delete_ok( $ua, '/productorder/delete',     [$product_order_id],       'ProductOrder delete' );

# 9. MeasurementBatch
delete_ok( $ua, '/measurementbatch/delete', [$measurement_batch_id],   'MeasurementBatch delete' );

# 8. StillageLocation
delete_ok( $ua, '/stillagelocation/delete', [$stillage_location_id],   'StillageLocation delete' );

# 7. OrderBatch
delete_ok( $ua, '/orderbatch/delete',       [$order_batch_id],         'OrderBatch delete' );

# 6. FestivalProduct
delete_ok( $ua, '/festivalproduct/delete',  [$festival_product_id],    'FestivalProduct delete' );

# 5. Product — must precede Company deletion.
delete_ok( $ua, '/product/delete',          [$product_id],             'Product delete' );

# 4. Telephone — must precede Contact deletion.
delete_ok( $ua, '/telephone/delete',        [$telephone_id],           'Telephone delete' );

# 3. Contact — must precede Company deletion.
delete_ok( $ua, '/contact/delete',          [$contact_id],             'Contact delete' );

# 2. Company
delete_ok( $ua, '/company/delete',          [$company_id],             'Company delete' );

# 1. Festival
delete_ok( $ua, '/festival/delete',         [$festival_id],            'Festival delete' );

done_testing();
