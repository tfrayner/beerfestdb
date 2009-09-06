package BeerFestDB::ORM::ProductCharacteristic;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("product_characteristic");
__PACKAGE__->add_columns(
  "product_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "product_characteristic_type_id_2",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "product_category_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "value",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
);
__PACKAGE__->set_primary_key("product_id");
__PACKAGE__->belongs_to(
  "product_characteristic_type",
  "BeerFestDB::ORM::ProductCharacteristicType",
  {
    product_category_id => "product_category_id",
    "product_characteristic_type_id" => "product_characteristic_type_id_2",
  },
);
__PACKAGE__->belongs_to(
  "product_id",
  "BeerFestDB::ORM::Product",
  { product_id => "product_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IHOzZXbsiHFq404cAYV70Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
