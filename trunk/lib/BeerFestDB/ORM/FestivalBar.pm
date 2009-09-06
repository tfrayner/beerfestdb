package BeerFestDB::ORM::FestivalBar;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("festival_bar");
__PACKAGE__->add_columns(
  "bar_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "festival_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
);
__PACKAGE__->set_primary_key("bar_id", "festival_id");
__PACKAGE__->belongs_to("bar_id", "BeerFestDB::ORM::Bar", { bar_id => "bar_id" });
__PACKAGE__->belongs_to(
  "festival_id",
  "BeerFestDB::ORM::Festival",
  { festival_id => "festival_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dGkA2xN4/RA1BG/0mF+wOQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
