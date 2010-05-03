package BeerFestDB::ORM::StillageLocation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("stillage_location");
__PACKAGE__->add_columns(
  "stillage_location_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "festival_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("stillage_location_id");
__PACKAGE__->add_unique_constraint("description", ["description"]);
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.stillage_location_id" => "self.stillage_location_id" },
);
__PACKAGE__->belongs_to(
  "festival_id",
  "BeerFestDB::ORM::Festival",
  { festival_id => "festival_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-05-02 20:33:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DXVUqPFxXwR1tv2vDtmAkg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
