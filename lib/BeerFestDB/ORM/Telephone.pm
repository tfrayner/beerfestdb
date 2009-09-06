package BeerFestDB::ORM::Telephone;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("telephone");
__PACKAGE__->add_columns(
  "telephone_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "telephone_type_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "interational_code",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "area_code",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "telephone",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "extension",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
);
__PACKAGE__->set_primary_key("telephone_id");
__PACKAGE__->has_many(
  "contact_telephones",
  "BeerFestDB::ORM::ContactTelephone",
  { "foreign.telephone_id" => "self.telephone_id" },
);
__PACKAGE__->belongs_to(
  "telephone_type_id",
  "BeerFestDB::ORM::TelephoneType",
  { telephone_type_id => "telephone_type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P+HelscseVKBW7DoSiSyWw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
