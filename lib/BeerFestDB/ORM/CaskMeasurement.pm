package BeerFestDB::ORM::CaskMeasurement;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cask_measurement");
__PACKAGE__->add_columns(
  "cask_measurement_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "cask_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "date",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "start_date",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "end_date",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "volume",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 6 },
  "comment",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("cask_measurement_id");
__PACKAGE__->belongs_to("cask_id", "BeerFestDB::ORM::Cask", { cask_id => "cask_id" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uQoz1la6+V0E+cEu0kAWuA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
