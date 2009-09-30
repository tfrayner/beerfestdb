package BeerFestDB::ORM::TelephoneType;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("telephone_type");
__PACKAGE__->add_columns(
  "telephone_type_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 30,
  },
);
__PACKAGE__->set_primary_key("telephone_type_id");
__PACKAGE__->has_many(
  "telephones",
  "BeerFestDB::ORM::Telephone",
  { "foreign.telephone_type_id" => "self.telephone_type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 00:22:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:twaTX2GIIoK8cgpiLI1qpg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
