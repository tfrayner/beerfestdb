package BeerFestDB::ORM::Cask;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cask");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "brewer",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "beer",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "gyle",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "distributor",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 6 },
  "festival",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "size",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 2 },
  "cask_price",
  { data_type => "DECIMAL", default_value => undef, is_nullable => 1, size => 5 },
  "bar",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "comment",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to("brewer", "BeerFestDB::ORM::Company", { id => "brewer" });
__PACKAGE__->belongs_to("beer", "BeerFestDB::ORM::Beer", { id => "beer" });
__PACKAGE__->belongs_to("gyle", "BeerFestDB::ORM::Gyle", { id => "gyle" });
__PACKAGE__->belongs_to(
  "distributor",
  "BeerFestDB::ORM::Company",
  { id => "distributor" },
);
__PACKAGE__->belongs_to("festival", "BeerFestDB::ORM::Festival", { id => "festival" });
__PACKAGE__->belongs_to("bar", "BeerFestDB::ORM::Bar", { id => "bar" });
__PACKAGE__->has_many(
  "cask_measurements",
  "BeerFestDB::ORM::CaskMeasurement",
  { "foreign.cask" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-01-25 16:03:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5qz8KZ5GlKyrVeTh1SO7Vg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
