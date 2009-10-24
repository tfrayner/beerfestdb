package BeerFestDB::ORM::ProductCharacteristic;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("product_characteristic");
__PACKAGE__->add_columns(
  "product_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "product_characteristic_type_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "value",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
);
__PACKAGE__->set_primary_key("product_id");
__PACKAGE__->belongs_to(
  "product_characteristic_type_id",
  "BeerFestDB::ORM::ProductCharacteristicType",
  {
    "product_characteristic_type_id" => "product_characteristic_type_id",
  },
);
__PACKAGE__->belongs_to(
  "product_id",
  "BeerFestDB::ORM::Product",
  { product_id => "product_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-24 18:45:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DA5qGxEsZ2fMjB5tIIDjVg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
