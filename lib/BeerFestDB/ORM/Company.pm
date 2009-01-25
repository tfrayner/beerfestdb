package BeerFestDB::ORM::Company;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("company");
__PACKAGE__->add_columns(
  "id",
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
  "comment",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.distributor" => "self.id" },
);
__PACKAGE__->has_many(
  "company_addresses",
  "BeerFestDB::ORM::CompanyAddress",
  { "foreign.company" => "self.id" },
);
__PACKAGE__->has_many(
  "gyles",
  "BeerFestDB::ORM::Gyle",
  { "foreign.brewer" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-01-25 17:23:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PI4GfXOoIOrosNfw4H5wEA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
