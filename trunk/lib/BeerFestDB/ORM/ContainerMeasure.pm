package BeerFestDB::ORM::ContainerMeasure;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("container_measure");
__PACKAGE__->add_columns(
  "container_measure_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "litre_multiplier",
  { data_type => "FLOAT", default_value => undef, is_nullable => 0, size => 32 },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("container_measure_id");
__PACKAGE__->has_many(
  "cask_measurements",
  "BeerFestDB::ORM::CaskMeasurement",
  { "foreign.container_measure_id" => "self.container_measure_id" },
);
__PACKAGE__->has_many(
  "container_sizes",
  "BeerFestDB::ORM::ContainerSize",
  { "foreign.container_measure_id" => "self.container_measure_id" },
);
__PACKAGE__->has_many(
  "sale_volumes",
  "BeerFestDB::ORM::SaleVolume",
  { "foreign.container_measure_id" => "self.container_measure_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 00:22:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l0siz3OBmJOtgIrdR66/cw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
