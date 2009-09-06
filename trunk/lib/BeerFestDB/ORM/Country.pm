package BeerFestDB::ORM::Country;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("country");
__PACKAGE__->add_columns(
  "country_code_iso2",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 2 },
  "country_code_iso3",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 3 },
  "country_code_num3",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 3 },
  "country_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
);
__PACKAGE__->set_primary_key("country_code_iso2");
__PACKAGE__->has_many(
  "contacts",
  "BeerFestDB::ORM::Contact",
  { "foreign.country_code_iso2" => "self.country_code_iso2" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5Pza/GwgowBfG7GYlNhmSQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
