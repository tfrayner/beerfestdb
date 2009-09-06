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
    is_nullable => 1,
    size => 30,
  },
);
__PACKAGE__->set_primary_key("telephone_type_id");
__PACKAGE__->has_many(
  "telephones",
  "BeerFestDB::ORM::Telephone",
  { "foreign.telephone_type_id" => "self.telephone_type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jLKrCzoHPGj/HZn9fqcttQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
