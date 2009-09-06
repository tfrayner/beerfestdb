package BeerFestDB::ORM::FestivalEntry;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("festival_entry");
__PACKAGE__->add_columns(
  "festival_opening_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "festival_entry_type_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "currency_code",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 3 },
  "price",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("festival_opening_id", "festival_entry_type_id");
__PACKAGE__->belongs_to(
  "festival_opening_id",
  "BeerFestDB::ORM::FestivalOpening",
  { festival_opening_id => "festival_opening_id" },
);
__PACKAGE__->belongs_to(
  "festival_entry_type_id",
  "BeerFestDB::ORM::FestivalEntryType",
  { "festival_entry_type_id" => "festival_entry_type_id" },
);
__PACKAGE__->belongs_to(
  "currency_code",
  "BeerFestDB::ORM::Currency",
  { currency_code => "currency_code" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dqHgnejszCUbtyHvixDB/A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
