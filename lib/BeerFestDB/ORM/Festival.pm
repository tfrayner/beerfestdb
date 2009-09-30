package BeerFestDB::ORM::Festival;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("festival");
__PACKAGE__->add_columns(
  "festival_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "year",
  { data_type => "YEAR", default_value => undef, is_nullable => 0, size => 4 },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 60,
  },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "fst_start_date",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "fst_end_date",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("festival_id");
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.festival_id" => "self.festival_id" },
);
__PACKAGE__->has_many(
  "festival_bars",
  "BeerFestDB::ORM::FestivalBar",
  { "foreign.festival_id" => "self.festival_id" },
);
__PACKAGE__->has_many(
  "festival_openings",
  "BeerFestDB::ORM::FestivalOpening",
  { "foreign.festival_id" => "self.festival_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 00:22:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9NayPtT6q3ZCE9dxT/Y40A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
