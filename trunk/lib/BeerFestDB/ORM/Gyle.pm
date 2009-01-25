package BeerFestDB::ORM::Gyle;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("gyle");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "brewery_number",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "brewer",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "beer",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "abv",
  { data_type => "DECIMAL", default_value => undef, is_nullable => 1, size => 3 },
  "pint_price",
  { data_type => "DECIMAL", default_value => undef, is_nullable => 1, size => 4 },
  "comment",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.gyle" => "self.id" },
);
__PACKAGE__->belongs_to("brewer", "BeerFestDB::ORM::Company", { id => "brewer" });
__PACKAGE__->belongs_to("beer", "BeerFestDB::ORM::Beer", { id => "beer" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-01-25 16:03:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:x2/fz0br0nRsl/c8AA68iA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
