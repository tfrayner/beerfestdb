package BeerFestDB::ORM::ContainerSize;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("container_size");
__PACKAGE__->add_columns(
  "container_size_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "container_volume",
  { data_type => "DECIMAL", default_value => undef, is_nullable => 0, size => 4 },
  "container_measure_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "container_description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
);
__PACKAGE__->set_primary_key("container_size_id");
__PACKAGE__->add_unique_constraint("container_description", ["container_description"]);
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.container_size_id" => "self.container_size_id" },
);
__PACKAGE__->belongs_to(
  "container_measure_id",
  "BeerFestDB::ORM::ContainerMeasure",
  { container_measure_id => "container_measure_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-05-02 20:33:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:omnNG60ZnKWwdW8tWHzF+A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
