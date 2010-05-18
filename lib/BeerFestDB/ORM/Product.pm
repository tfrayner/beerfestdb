package BeerFestDB::ORM::Product;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("product");
__PACKAGE__->add_columns(
  "product_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "company_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "product_category_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "product_style_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 6 },
  "nominal_abv",
  { data_type => "DECIMAL", default_value => undef, is_nullable => 1, size => 3 },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "comment",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("product_id");
__PACKAGE__->add_unique_constraint("company_id", ["company_id", "name"]);
__PACKAGE__->has_many(
  "festival_products",
  "BeerFestDB::ORM::FestivalProduct",
  { "foreign.product_id" => "self.product_id" },
);
__PACKAGE__->has_many(
  "gyles",
  "BeerFestDB::ORM::Gyle",
  { "foreign.product_id" => "self.product_id" },
);
__PACKAGE__->belongs_to(
  "company_id",
  "BeerFestDB::ORM::Company",
  { company_id => "company_id" },
);
__PACKAGE__->belongs_to(
  "product_category_id",
  "BeerFestDB::ORM::ProductCategory",
  { product_category_id => "product_category_id" },
);
__PACKAGE__->belongs_to(
  "product_style_id",
  "BeerFestDB::ORM::ProductStyle",
  { product_style_id => "product_style_id" },
);
__PACKAGE__->has_many(
  "product_characteristics",
  "BeerFestDB::ORM::ProductCharacteristic",
  { "foreign.product_id" => "self.product_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-05-18 12:04:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bN5yQnsJ9rEQ2WRCbBgtvQ


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->many_to_many(
    "festivals" => "festival_products", "festival_id"
);

1;
