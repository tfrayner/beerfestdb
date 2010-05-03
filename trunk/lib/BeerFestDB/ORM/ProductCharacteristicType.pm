package BeerFestDB::ORM::ProductCharacteristicType;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("product_characteristic_type");
__PACKAGE__->add_columns(
  "product_characteristic_type_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "product_category_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("product_characteristic_type_id", "product_category_id");
__PACKAGE__->add_unique_constraint("product_category_id", ["product_category_id", "description"]);
__PACKAGE__->has_many(
  "product_characteristics",
  "BeerFestDB::ORM::ProductCharacteristic",
  {
    "foreign.product_characteristic_type_id" => "self.product_characteristic_type_id",
  },
);
__PACKAGE__->belongs_to(
  "product_category_id",
  "BeerFestDB::ORM::ProductCategory",
  { product_category_id => "product_category_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-05-02 20:33:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uZ6kZJB3Od7f3h7O+tLMfQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
