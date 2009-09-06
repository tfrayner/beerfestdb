package BeerFestDB::ORM::ContactTelephone;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("contact_telephone");
__PACKAGE__->add_columns(
  "contact_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "telephone_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
);
__PACKAGE__->set_primary_key("contact_id", "telephone_id");
__PACKAGE__->belongs_to(
  "contact_id",
  "BeerFestDB::ORM::Contact",
  { contact_id => "contact_id" },
);
__PACKAGE__->belongs_to(
  "telephone_id",
  "BeerFestDB::ORM::Telephone",
  { telephone_id => "telephone_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IjxUfzst+JJ4FAR8l733/g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
