package BeerFestDB::ORM::Bar;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bar");
__PACKAGE__->add_columns(
  "bar_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "festival_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "is_private",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("bar_id");
__PACKAGE__->add_unique_constraint("description", ["description"]);
__PACKAGE__->belongs_to(
  "festival_id",
  "BeerFestDB::ORM::Festival",
  { festival_id => "festival_id" },
);
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.bar_id" => "self.bar_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-05-02 20:33:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qAKop6XOCwh/mMgfW2lHcQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
