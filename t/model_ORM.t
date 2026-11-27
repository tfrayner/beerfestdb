use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(schema);

# -----------------------------------------------------------------------
# Compile tests for all ORM result classes.
# -----------------------------------------------------------------------

BEGIN {
    use_ok 'BeerFestDB::ORM';
    use_ok 'BeerFestDB::ORM::Bar';
    use_ok 'BeerFestDB::ORM::BayPosition';
    use_ok 'BeerFestDB::ORM::Cask';
    use_ok 'BeerFestDB::ORM::CaskManagement';
    use_ok 'BeerFestDB::ORM::CaskMeasurement';
    use_ok 'BeerFestDB::ORM::CategoryAuth';
    use_ok 'BeerFestDB::ORM::Company';
    use_ok 'BeerFestDB::ORM::CompanyRegion';
    use_ok 'BeerFestDB::ORM::Contact';
    use_ok 'BeerFestDB::ORM::ContactType';
    use_ok 'BeerFestDB::ORM::ContainerMeasure';
    use_ok 'BeerFestDB::ORM::ContainerSize';
    use_ok 'BeerFestDB::ORM::Country';
    use_ok 'BeerFestDB::ORM::Currency';
    use_ok 'BeerFestDB::ORM::DispenseMethod';
    use_ok 'BeerFestDB::ORM::Festival';
    use_ok 'BeerFestDB::ORM::FestivalEntry';
    use_ok 'BeerFestDB::ORM::FestivalEntryType';
    use_ok 'BeerFestDB::ORM::FestivalOpening';
    use_ok 'BeerFestDB::ORM::FestivalProduct';
    use_ok 'BeerFestDB::ORM::Gyle';
    use_ok 'BeerFestDB::ORM::MeasurementBatch';
    use_ok 'BeerFestDB::ORM::OrderBatch';
    use_ok 'BeerFestDB::ORM::OrderSummaryView';
    use_ok 'BeerFestDB::ORM::Product';
    use_ok 'BeerFestDB::ORM::ProductAllergen';
    use_ok 'BeerFestDB::ORM::ProductAllergenType';
    use_ok 'BeerFestDB::ORM::ProductCategory';
    use_ok 'BeerFestDB::ORM::ProductCharacteristic';
    use_ok 'BeerFestDB::ORM::ProductCharacteristicType';
    use_ok 'BeerFestDB::ORM::ProductOrder';
    use_ok 'BeerFestDB::ORM::ProductStyle';
    use_ok 'BeerFestDB::ORM::ProgrammeNotesView';
    use_ok 'BeerFestDB::ORM::Protected';
    use_ok 'BeerFestDB::ORM::Role';
    use_ok 'BeerFestDB::ORM::SaleVolume';
    use_ok 'BeerFestDB::ORM::StillageLocation';
    use_ok 'BeerFestDB::ORM::SystemDefaults';
    use_ok 'BeerFestDB::ORM::Telephone';
    use_ok 'BeerFestDB::ORM::TelephoneType';
    use_ok 'BeerFestDB::ORM::User';
    use_ok 'BeerFestDB::ORM::UserRole';
}

# -----------------------------------------------------------------------
# repr() tests using fixture objects from the test database.
# -----------------------------------------------------------------------

my $db = schema();

# Simple scalar-returning repr methods.
my $festival = $db->resultset('Festival')->find(1);
ok( $festival, 'Festival fixture exists' );
is( $festival->repr(), 'TestFestival', 'Festival::repr returns name' );

my $company = $db->resultset('Company')->find(1);
ok( $company, 'Company fixture exists' );
is( $company->repr(), 'TestBrewer', 'Company::repr returns name' );

my $product = $db->resultset('Product')->find(1);
ok( $product, 'Product fixture exists' );
is( $product->repr(), 'TestBeer', 'Product::repr returns name' );

my $stillage = $db->resultset('StillageLocation')->find(1);
ok( $stillage, 'StillageLocation fixture exists' );
is( $stillage->repr(), 'TestStillage', 'StillageLocation::repr returns description' );

my $order_batch = $db->resultset('OrderBatch')->find(1);
ok( $order_batch, 'OrderBatch fixture exists' );
is( $order_batch->repr(), 'TestFestival: TestOrderBatch',
    'OrderBatch::repr returns festival and description' );

# Derived repr methods that delegate to related objects.
my $fp = $db->resultset('FestivalProduct')->find(1);
ok( $fp, 'FestivalProduct fixture exists' );
is( $fp->repr(), 'TestBeer', 'FestivalProduct::repr delegates to Product' );

my $gyle = $db->resultset('Gyle')->find(1);
ok( $gyle, 'Gyle fixture exists' );
is( $gyle->repr(), 'TestBeer: 1', 'Gyle::repr returns product and internal_reference' );

my $cask_mgmt = $db->resultset('CaskManagement')->find(1);
ok( $cask_mgmt, 'CaskManagement fixture exists' );
is( $cask_mgmt->repr(), 'firkin', 'CaskManagement::repr returns container size description' );

my $cask = $db->resultset('Cask')->find(1);
ok( $cask, 'Cask fixture exists' );
is( $cask->repr(), 'TestBeer: firkin', 'Cask::repr returns product and container size' );

my $batch = $db->resultset('MeasurementBatch')->find(1);
ok( $batch, 'MeasurementBatch fixture exists' );
is( $batch->repr(), 'TestFestival: 1970-01-01 01:00:00',
    'MeasurementBatch::repr returns festival and measurement_time' );

my $meas = $db->resultset('CaskMeasurement')->find(1);
ok( $meas, 'CaskMeasurement fixture exists' );
is( $meas->repr(),
    'TestBeer: firkin: TestFestival: 1970-01-01 01:00:00',
    'CaskMeasurement::repr delegates to Cask and MeasurementBatch' );

my $contact = $db->resultset('Contact')->find(1);
ok( $contact, 'Contact fixture exists' );
is( $contact->repr(), 'TestBrewer: Main', 'Contact::repr returns company and contact_type' );

my $telephone = $db->resultset('Telephone')->find(1);
ok( $telephone, 'Telephone fixture exists' );
is( $telephone->repr(), 'TestBrewer: Main: landline',
    'Telephone::repr delegates to Contact and TelephoneType' );

# Vocabulary repr methods.
my $currency = $db->resultset('Currency')->find(1);
ok( $currency, 'Currency fixture (GBP) exists' );
is( $currency->repr(), 'GBP', 'Currency::repr returns currency_code' );

my $container_size = $db->resultset('ContainerSize')->find(1);
ok( $container_size, 'ContainerSize fixture (firkin) exists' );
is( $container_size->repr(), 'firkin', 'ContainerSize::repr returns description' );

done_testing();
