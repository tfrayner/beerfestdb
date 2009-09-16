package BeerFestDB::ORM::SaleVolume;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("sale_volume");
__PACKAGE__->add_columns(
  "sale_volume_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "container_measure_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "sale_volume_description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 30,
  },
  "volume",
  { data_type => "DECIMAL", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("sale_volume_id");
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.sale_volume_id" => "self.sale_volume_id" },
);
__PACKAGE__->belongs_to(
  "container_measure_id",
  "BeerFestDB::ORM::ContainerMeasure",
  { container_measure_id => "container_measure_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-16 21:32:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bjpZ8ad0XuBDqtL2+yBuBw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
