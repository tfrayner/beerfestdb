package BeerFestDB::ORM::Contact;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("contact");
__PACKAGE__->add_columns(
  "contact_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "contact_type_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 4 },
  "last_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "first_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "street_address",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "postcode",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "country_code_iso2",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 2 },
  "comment",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("contact_id");
__PACKAGE__->has_many(
  "company_contacts",
  "BeerFestDB::ORM::CompanyContact",
  { "foreign.contact_id" => "self.contact_id" },
);
__PACKAGE__->belongs_to(
  "contact_type_id",
  "BeerFestDB::ORM::ContactType",
  { contact_type_id => "contact_type_id" },
);
__PACKAGE__->belongs_to(
  "country_code_iso2",
  "BeerFestDB::ORM::Country",
  { country_code_iso2 => "country_code_iso2" },
);
__PACKAGE__->has_many(
  "contact_telephones",
  "BeerFestDB::ORM::ContactTelephone",
  { "foreign.contact_id" => "self.contact_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Bnx81POg3isJ4Z/GCvNbfw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
