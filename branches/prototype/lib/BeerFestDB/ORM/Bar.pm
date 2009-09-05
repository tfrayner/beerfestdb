package BeerFestDB::ORM::Bar;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bar");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.bar" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-01-25 16:03:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8tF6HQPYROYjS2hiS254Pw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
