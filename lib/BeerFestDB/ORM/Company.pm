package BeerFestDB::ORM::Company;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("company");
__PACKAGE__->add_columns(
  "company_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "loc_desc",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "year_founded",
  { data_type => "YEAR", default_value => undef, is_nullable => 1, size => 4 },
  "url",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "comment",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("company_id");
__PACKAGE__->add_unique_constraint("name", ["name"]);
__PACKAGE__->has_many(
  "company_contacts",
  "BeerFestDB::ORM::CompanyContact",
  { "foreign.company_id" => "self.company_id" },
);
__PACKAGE__->has_many(
  "company_products",
  "BeerFestDB::ORM::CompanyProduct",
  { "foreign.company_id" => "self.company_id" },
);
__PACKAGE__->has_many(
  "gyles",
  "BeerFestDB::ORM::Gyle",
  { "foreign.company_id" => "self.company_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-05-02 20:33:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HVUP54oJLBy0XoHO/Zd8eA


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->many_to_many(
    "products" => "company_products", "product_id"
);

1;
