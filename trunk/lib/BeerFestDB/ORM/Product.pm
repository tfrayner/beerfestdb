package BeerFestDB::ORM::Product;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("product");
__PACKAGE__->add_columns(
  "product_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
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
  "sale_volume_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "sale_currency_code",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 3 },
  "sale_price",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
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
__PACKAGE__->has_many(
  "company_products",
  "BeerFestDB::ORM::CompanyProduct",
  { "foreign.product_id" => "self.product_id" },
);
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
  "product_category_id",
  "BeerFestDB::ORM::ProductCategory",
  { product_category_id => "product_category_id" },
);
__PACKAGE__->belongs_to(
  "product_style_id",
  "BeerFestDB::ORM::ProductStyle",
  { product_style_id => "product_style_id" },
);
__PACKAGE__->belongs_to(
  "sale_volume_id",
  "BeerFestDB::ORM::SaleVolume",
  { sale_volume_id => "sale_volume_id" },
);
__PACKAGE__->belongs_to(
  "sale_currency_code",
  "BeerFestDB::ORM::Currency",
  { currency_code => "sale_currency_code" },
);
__PACKAGE__->has_many(
  "product_characteristics",
  "BeerFestDB::ORM::ProductCharacteristic",
  { "foreign.product_id" => "self.product_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-05-16 17:45:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aA09Ph7tOdcn0SsNczPulA


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->many_to_many(
    "producers" => "company_products", "company_id"
);
__PACKAGE__->many_to_many(
    "festivals" => "festival_products", "festival_id"
);

1;
