package BeerFestDB::ORM::StillageLocation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("stillage_location");
__PACKAGE__->add_columns(
  "stillage_location_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("stillage_location_id");
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.stillage_location_id" => "self.stillage_location_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 00:22:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:M9AxA3LLHYyWRHT9vBh/uQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
