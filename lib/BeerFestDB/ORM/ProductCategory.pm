package BeerFestDB::ORM::ProductCategory;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("product_category");
__PACKAGE__->add_columns(
  "product_category_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
);
__PACKAGE__->set_primary_key("product_category_id");
__PACKAGE__->has_many(
  "products",
  "BeerFestDB::ORM::Product",
  { "foreign.product_category_id" => "self.product_category_id" },
);
__PACKAGE__->has_many(
  "product_characteristic_types",
  "BeerFestDB::ORM::ProductCharacteristicType",
  { "foreign.product_category_id" => "self.product_category_id" },
);
__PACKAGE__->has_many(
  "product_styles",
  "BeerFestDB::ORM::ProductStyle",
  { "foreign.product_category_id" => "self.product_category_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-24 18:45:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:++eJF/gzfHFnjmBtkHUDVw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
