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

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);
use TestGenericGrid qw(generic_grid_tests);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }

# Verify all controllers compile. OpenIDConnect is optional (requires plugin).
use_ok $_ for qw(
    BeerFestDB::Web::Controller::Bar
    BeerFestDB::Web::Controller::BayPosition
    BeerFestDB::Web::Controller::Cask
    BeerFestDB::Web::Controller::CaskMeasurement
    BeerFestDB::Web::Controller::Company
    BeerFestDB::Web::Controller::CompanyRegion
    BeerFestDB::Web::Controller::Contact
    BeerFestDB::Web::Controller::ContactType
    BeerFestDB::Web::Controller::ContainerMeasure
    BeerFestDB::Web::Controller::ContainerSize
    BeerFestDB::Web::Controller::Country
    BeerFestDB::Web::Controller::Currency
    BeerFestDB::Web::Controller::DispenseMethod
    BeerFestDB::Web::Controller::Festival
    BeerFestDB::Web::Controller::FestivalProduct
    BeerFestDB::Web::Controller::Gyle
    BeerFestDB::Web::Controller::MeasurementBatch
    BeerFestDB::Web::Controller::OrderBatch
    BeerFestDB::Web::Controller::Product
    BeerFestDB::Web::Controller::ProductAllergenType
    BeerFestDB::Web::Controller::ProductCategory
    BeerFestDB::Web::Controller::ProductCharacteristicType
    BeerFestDB::Web::Controller::ProductOrder
    BeerFestDB::Web::Controller::ProductStyle
    BeerFestDB::Web::Controller::Protected
    BeerFestDB::Web::Controller::Role
    BeerFestDB::Web::Controller::SaleVolume
    BeerFestDB::Web::Controller::StillageLocation
    BeerFestDB::Web::Controller::SystemDefaults
    BeerFestDB::Web::Controller::Telephone
    BeerFestDB::Web::Controller::TelephoneType
    BeerFestDB::Web::Controller::User
);

# Note: OpenIDConnect will not load if the optional plugin is not installed.
SKIP: {
    eval { require BeerFestDB::Web::Controller::OpenIDConnect };
    skip 'BeerFestDB::Web::Controller::OpenIDConnect not loadable (optional plugin absent)', 1
        if $@;
    pass('BeerFestDB::Web::Controller::OpenIDConnect loaded');
}

# Authenticated user agents, created once for all tests.
my $admin  = authenticated_user("admin",  "admin");
my $cellar = authenticated_user("cellar", "cellar");

# ---------------------------------------------------------------------------
subtest 'Bar' => sub {
    $admin->get_ok('/bar', 'index should succeed');
};

# ---------------------------------------------------------------------------
subtest 'BayPosition' => sub {
    $admin->get_ok('/bayposition/list', 'list should succeed');
};

# ---------------------------------------------------------------------------
subtest 'Cask' => sub {
    $cellar->get_ok('/cask/view/1',                        'view should succeed');
#    $cellar->get_ok('/cask/list/1/1',                      'list should succeed');
#    $cellar->get_ok('/cask/grid/1/1',                      'grid should succeed');
    $cellar->get_ok('/cask/load_form',                     'load_form should succeed');
    $cellar->get_ok('/cask/list_by_stillage/1',            'list_by_stillage should succeed');
    $cellar->get_ok('/cask/list_by_festival_product/1',    'list_by_festival_product should succeed');
    $cellar->get_ok('/cask/list_dips/1',                   'list_dips should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/cask/submit',                       'submit should succeed');
    #$cellar->get_ok('/cask/delete',                       'delete should succeed');
    #$cellar->get_ok('/cask/delete_from_stillage',         'delete_from_stillage should succeed');
};

# ---------------------------------------------------------------------------
subtest 'CaskManagement' => sub {
    $cellar->get_ok('/caskmanagement/view/1',              'view should succeed');
    $cellar->get_ok('/caskmanagement/list/1/1',            'list should succeed');
    $cellar->get_ok('/caskmanagement/grid/1/1',            'grid should succeed');
    $cellar->get_ok('/caskmanagement/load_form',           'load_form should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/caskmanagement/submit',             'submit should succeed');
    #$cellar->get_ok('/caskmanagement/delete',             'delete should succeed');
    #$cellar->get_ok('/caskmanagement/delete_from_stillage', 'delete_from_stillage should succeed');
};

# ---------------------------------------------------------------------------
subtest 'CaskMeasurement' => sub {
    $cellar->get_ok('/caskmeasurement/view/1',          'view should succeed');
    $cellar->get_ok('/caskmeasurement/load_form',       'load_form should succeed');
    $cellar->get_ok('/caskmeasurement/list/1/1',        'list should succeed');
    $cellar->get_ok('/caskmeasurement/list_by_cask/1',  'list_by_cask should succeed');
    $cellar->get_ok('/caskmeasurement/grid/1/1',        'grid should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/caskmeasurement/submit',          'submit should succeed');
    #$cellar->get_ok('/caskmeasurement/delete',          'delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'Company' => sub {
    $cellar->get_ok('/company/view/1',   'view should succeed');
    $cellar->get_ok('/company/load_form','load_form should succeed');
    $cellar->get_ok('/company/list',     'list should succeed');
    $cellar->get_ok('/company/grid',     'grid should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/company/submit',  'submit should succeed');
    #$cellar->get_ok('/company/delete',  'delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'CompanyRegion' => sub {
    generic_grid_tests("companyregion", "CompanyRegion", $admin);
    $admin->get_ok('/companyregion/view/1',    'view should succeed');
    $admin->get_ok('/companyregion/load_form', 'load_form should succeed');
};

# ---------------------------------------------------------------------------
subtest 'Contact' => sub {
    $cellar->get_ok('/contact/view/1',             'view should succeed');
    $cellar->get_ok('/contact/load_form',           'load_form should succeed');
    $cellar->get_ok('/contact/list_by_company/1',   'list_by_company should succeed');
    # Template not yet implemented:
    #$cellar->get_ok('/contact/grid/1',             'grid should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/contact/submit',             'submit should succeed');
    #$cellar->get_ok('/contact/delete',             'delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'ContactType' => sub {
    $cellar->get_ok('/contacttype/list', 'list should succeed');
};

# ---------------------------------------------------------------------------
subtest 'ContainerMeasure' => sub {
    # grid not yet implemented:
    generic_grid_tests("containermeasure", "ContainerMeasure", $admin, 1);
};

# ---------------------------------------------------------------------------
subtest 'ContainerSize' => sub {
    generic_grid_tests("containersize", "ContainerSize", $admin);
    $admin->get_ok('/containersize/view/1',    'view should succeed');
    $admin->get_ok('/containersize/load_form', 'load_form should succeed');
};

# ---------------------------------------------------------------------------
subtest 'Country' => sub {
    $cellar->get_ok('/country/list', 'list should succeed');
};

# ---------------------------------------------------------------------------
subtest 'Currency' => sub {
    $admin->get_ok('/currency/list', 'list should succeed');
};

# ---------------------------------------------------------------------------
subtest 'DispenseMethod' => sub {
    generic_grid_tests("dispensemethod", "DispenseMethod", $admin);
    $admin->get_ok('/dispensemethod/view/1',    'view should succeed');
    $admin->get_ok('/dispensemethod/load_form', 'load_form should succeed');
};

# ---------------------------------------------------------------------------
subtest 'Festival' => sub {
    $cellar->get_ok('/festival',             'index should succeed');
    $cellar->get_ok('/festival/view/1',      'view should succeed');
    $cellar->get_ok('/festival/list/1/1',    'list should succeed');
    $cellar->get_ok('/festival/grid/1/1',    'grid should succeed');
    $cellar->get_ok('/festival/load_form',   'load_form should succeed');
    $cellar->get_ok('/festival/status/1',    'status should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/festival/submit',     'submit should succeed');
    #$cellar->get_ok('/festival/delete',     'delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'FestivalProduct' => sub {
    $cellar->get_ok('/festivalproduct',                      'index should succeed');
    $cellar->get_ok('/festivalproduct/view/1',               'view should succeed');
    $cellar->get_ok('/festivalproduct/list/1/1',             'list should succeed');
    $cellar->get_ok('/festivalproduct/grid/1/1',             'grid should succeed');
    $cellar->get_ok('/festivalproduct/load_form',            'load_form should succeed');
    $cellar->get_ok('/festivalproduct/list_by_product/1',    'list_by_product should succeed');
    $cellar->get_ok('/festivalproduct/list_by_company/1',    'list_by_company should succeed');
    $cellar->get_ok('/festivalproduct/list_status/1/1',      'list_status should succeed');
    # Deprecated:
    #$cellar->get_ok('/festivalproduct/html_status_list/1/1','html_status_list should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/festivalproduct/submit',              'submit should succeed');
    #$cellar->get_ok('/festivalproduct/delete',              'delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'Gyle' => sub {
    $cellar->get_ok('/gyle',                              'index should succeed');
    $cellar->get_ok('/gyle/view/1',                       'view should succeed');
    $cellar->get_ok('/gyle/list_by_festival_product/1',   'list_by_festival_product should succeed');
    $cellar->get_ok('/gyle/list_by_festival/1',           'list_by_festival should succeed');
    $cellar->get_ok('/gyle/load_form',                    'load_form should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/gyle/submit',                      'submit should succeed');
    #$cellar->get_ok('/gyle/delete',                      'delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'MeasurementBatch' => sub {
    $cellar->get_ok('/measurementbatch',          'index should succeed');
    $cellar->get_ok('/measurementbatch/view/1',   'view should succeed');
    $cellar->get_ok('/measurementbatch/list/1',   'list should succeed');
    # Template not yet implemented:
    #$cellar->get_ok('/measurementbatch/grid/1',  'grid should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/measurementbatch/submit',  'submit should succeed');
    #$cellar->get_ok('/measurementbatch/delete',  'delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'OrderBatch' => sub {
    $cellar->get_ok('/orderbatch',          'index should succeed');
    $cellar->get_ok('/orderbatch/list/1',   'list should succeed');
    $cellar->get_ok('/orderbatch/view/1',   'view should succeed');
    # Template not yet implemented:
    #$cellar->get_ok('/orderbatch/grid/1',  'grid should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/orderbatch/submit',  'submit should succeed');
    #$cellar->get_ok('/orderbatch/delete',  'delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'Product' => sub {
    $cellar->get_ok('/product',                         'index should succeed');
    $cellar->get_ok('/product/view/1',                  'view should succeed');
    $cellar->get_ok('/product/list/1/1',                'list should succeed');
    $cellar->get_ok('/product/grid/1/1',                'grid should succeed');
    $cellar->get_ok('/product/load_form',               'load_form should succeed');
    $cellar->get_ok('/product/list_by_company/1/1',     'list_by_company should succeed');
    $cellar->get_ok('/product/list_by_festival/1/2',    'list_by_festival should succeed');
    $cellar->get_ok('/product/list_by_order_batch/1/1', 'list_by_order_batch should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/product/submit',                 'submit should succeed');
    #$cellar->get_ok('/product/delete',                 'delete should succeed');
    #$cellar->get_ok('/product/delete_from_stillage',   'delete_from_stillage should succeed');
};

# ---------------------------------------------------------------------------
subtest 'ProductAllergenType' => sub {
    generic_grid_tests("productallergentype", "ProductAllergenType", $admin);
    $admin->get_ok('/productallergentype/view/1',    'view should succeed');
    $admin->get_ok('/productallergentype/load_form', 'load_form should succeed');
};

# ---------------------------------------------------------------------------
subtest 'ProductCategory' => sub {
    generic_grid_tests("productcategory", "ProductCategory", $admin);
};

# ---------------------------------------------------------------------------
subtest 'ProductCharacteristicType' => sub {
    generic_grid_tests("productcharacteristictype", "ProductCharacteristicType", $admin);
    $admin->get_ok('/productcharacteristictype/view/1',              'view should succeed');
    $admin->get_ok('/productcharacteristictype/load_form',           'load_form should succeed');
    $admin->get_ok('/productcharacteristictype/list_by_category/2',  'list_by_category should succeed');
    # Needs JSON payload / confirmation:
    #$admin->get_ok('/productcharacteristictype/submit',             'submit should succeed');
    #$admin->get_ok('/productcharacteristictype/delete',             'delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'ProductOrder' => sub {
    $cellar->get_ok('/productorder/list/1/1', 'list should succeed');
    $cellar->get_ok('/productorder/grid/1/1', 'grid should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/productorder/submit',  'submit should succeed');
    #$cellar->get_ok('/productorder/delete',  'delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'ProductStyle' => sub {
    generic_grid_tests("productstyle", "ProductStyle", $admin);
    $admin->get_ok('/productstyle/view/1',              'view should succeed');
    $admin->get_ok('/productstyle/list_by_category/1',  'list_by_category should succeed');
    $admin->get_ok('/productstyle/load_form',           'load_form should succeed');
};

# ---------------------------------------------------------------------------
subtest 'Protected' => sub {
    # list is accessible to all authenticated users (user role).
    $cellar->get_ok('/protected/list',     'list should succeed');
    $admin->get_ok('/protected/grid',      'grid should succeed');
    # Protected id=1 ('Company') is seeded by initialise_vocabs.sql.
    $admin->get_ok('/protected/view/1',    'view should succeed');
    $admin->get_ok('/protected/load_form', 'load_form should succeed');
    # Needs JSON payload / confirmation:
    #$admin->get_ok('/protected/submit',   'submit should succeed');
    #$admin->get_ok('/protected/delete',   'delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'Role' => sub {
    $admin->get_ok('/role/list', 'list should succeed');
};

# ---------------------------------------------------------------------------
subtest 'SaleVolume' => sub {
    generic_grid_tests("salevolume", "SaleVolume", $admin);
    $admin->get_ok('/salevolume/view/1',    'view should succeed');
    $admin->get_ok('/salevolume/load_form', 'load_form should succeed');
};

# ---------------------------------------------------------------------------
subtest 'StillageLocation' => sub {
    $cellar->get_ok('/stillagelocation/list/1', 'list should succeed');
    $cellar->get_ok('/stillagelocation/grid/1', 'grid should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/stillagelocation/submit','submit should succeed');
    #$cellar->get_ok('/stillagelocation/delete','delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'SystemDefaults' => sub {
    # Singleton row (id=1) is seeded by initialise_vocabs.sql; admin-only.
    $admin->get_ok('/systemdefaults/view',          'view should succeed');
    $admin->get_ok('/systemdefaults/load_form?id=1', 'load_form should succeed');
    # Needs JSON payload / confirmation:
    #$admin->post_ok('/systemdefaults/submit', ..., 'submit should succeed');
    # delete is not supported (the controller rejects it with a flash error).
};

# ---------------------------------------------------------------------------
subtest 'Telephone' => sub {
    $cellar->get_ok('/telephone/view/1',             'view should succeed');
    $cellar->get_ok('/telephone/list_by_contact/1',  'list_by_contact should succeed');
    $cellar->get_ok('/telephone/load_form',          'load_form should succeed');
    # Needs JSON payload / confirmation:
    #$cellar->get_ok('/telephone/submit',             'submit should succeed');
    #$cellar->get_ok('/telephone/delete',             'delete should succeed');
};

# ---------------------------------------------------------------------------
subtest 'TelephoneType' => sub {
    $cellar->get_ok('/telephonetype/list', 'list should succeed');
};

# ---------------------------------------------------------------------------
subtest 'User' => sub {
    $admin->get_ok('/user/view/1',    'view should succeed');
    $admin->get_ok('/user/list',      'list should succeed');
    $admin->get_ok('/user/grid',      'grid should succeed');
    $admin->get_ok('/user/load_form', 'load_form should succeed');
    # Needs JSON payload / confirmation:
    #$admin->get_ok('/user/submit',   'submit should succeed');
    #$admin->get_ok('/user/delete',   'delete should succeed');
    #$admin->get_ok('/user/modify',   'modify should succeed');
};

done_testing();
