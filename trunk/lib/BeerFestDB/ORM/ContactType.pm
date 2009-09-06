package BeerFestDB::ORM::ContactType;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("contact_type");
__PACKAGE__->add_columns(
  "contact_type_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "contact_type_description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 30,
  },
);
__PACKAGE__->set_primary_key("contact_type_id");
__PACKAGE__->has_many(
  "contacts",
  "BeerFestDB::ORM::Contact",
  { "foreign.contact_type_id" => "self.contact_type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fyYv64cIN+CMWz7XxeUQEA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
