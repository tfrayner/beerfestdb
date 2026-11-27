use utf8;
package BeerFestDB::ORM::SystemDefaults;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("system_defaults");

__PACKAGE__->add_columns(
  "id",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
  "festival_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "currency_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sale_volume_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "product_category_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "container_measure_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "festival",
  "BeerFestDB::ORM::Festival",
  { "foreign.festival_id" => "self.festival_id" },
  { is_foreign_key_constraint => 1, join_type => "LEFT OUTER" },
);

__PACKAGE__->belongs_to(
  "currency",
  "BeerFestDB::ORM::Currency",
  { "foreign.currency_id" => "self.currency_id" },
  { is_foreign_key_constraint => 1, join_type => "LEFT OUTER" },
);

__PACKAGE__->belongs_to(
  "sale_volume",
  "BeerFestDB::ORM::SaleVolume",
  { "foreign.sale_volume_id" => "self.sale_volume_id" },
  { is_foreign_key_constraint => 1, join_type => "LEFT OUTER" },
);

__PACKAGE__->belongs_to(
  "product_category",
  "BeerFestDB::ORM::ProductCategory",
  { "foreign.product_category_id" => "self.product_category_id" },
  { is_foreign_key_constraint => 1, join_type => "LEFT OUTER" },
);

__PACKAGE__->belongs_to(
  "container_measure",
  "BeerFestDB::ORM::ContainerMeasure",
  { "foreign.container_measure_id" => "self.container_measure_id" },
  { is_foreign_key_constraint => 1, join_type => "LEFT OUTER" },
);

1;
