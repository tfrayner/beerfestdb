package BeerFestDB::ORM::FestivalOpening;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("festival_opening");
__PACKAGE__->add_columns(
  "festival_opening_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "festival_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "op_start_date",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
  "op_end_date",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("festival_opening_id");
__PACKAGE__->has_many(
  "festival_entries",
  "BeerFestDB::ORM::FestivalEntry",
  { "foreign.festival_opening_id" => "self.festival_opening_id" },
);
__PACKAGE__->belongs_to(
  "festival_id",
  "BeerFestDB::ORM::Festival",
  { festival_id => "festival_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4mSr90BQJp4n2vcdfIIBNA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
