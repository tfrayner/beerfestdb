package BeerFestDB::ORM::Festival;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("festival");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "year",
  { data_type => "YEAR", default_value => undef, is_nullable => 0, size => 4 },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 60,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.festival" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-01-25 16:03:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:x8LCaVuphyrjM3m8GN5SCA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
