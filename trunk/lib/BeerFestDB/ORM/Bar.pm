package BeerFestDB::ORM::Bar;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bar");
__PACKAGE__->add_columns(
  "bar_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("bar_id");
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.bar_id" => "self.bar_id" },
);
__PACKAGE__->has_many(
  "festival_bars",
  "BeerFestDB::ORM::FestivalBar",
  { "foreign.bar_id" => "self.bar_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:I+tuD1ge42VgHPlwHok6Kw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
