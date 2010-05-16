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
__PACKAGE__->add_unique_constraint("sale_volume_description", ["sale_volume_description"]);
__PACKAGE__->has_many(
  "festival_products",
  "BeerFestDB::ORM::FestivalProduct",
  { "foreign.sale_volume_id" => "self.sale_volume_id" },
);
__PACKAGE__->belongs_to(
  "container_measure_id",
  "BeerFestDB::ORM::ContainerMeasure",
  { container_measure_id => "container_measure_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-05-16 20:35:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ssoSXDVndUh6qODPEOfM0A


# You can replace this text with custom content, and it will be preserved on regeneration
1;