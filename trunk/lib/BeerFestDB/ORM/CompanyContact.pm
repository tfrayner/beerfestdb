package BeerFestDB::ORM::CompanyContact;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("company_contact");
__PACKAGE__->add_columns(
  "company_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "contact_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
);
__PACKAGE__->set_primary_key("company_id", "contact_id");
__PACKAGE__->belongs_to(
  "company_id",
  "BeerFestDB::ORM::Company",
  { company_id => "company_id" },
);
__PACKAGE__->belongs_to(
  "contact_id",
  "BeerFestDB::ORM::Contact",
  { contact_id => "contact_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9X6JhLp1L5qMHj9PDk7gaQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
