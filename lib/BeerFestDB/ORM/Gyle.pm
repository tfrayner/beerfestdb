package BeerFestDB::ORM::Gyle;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("gyle");
__PACKAGE__->add_columns(
  "gyle_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "company_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "product_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "abv",
  { data_type => "DECIMAL", default_value => undef, is_nullable => 1, size => 3 },
  "comment",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "external_reference",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "internal_reference",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("gyle_id");
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.gyle_id" => "self.gyle_id" },
);
__PACKAGE__->belongs_to(
  "company_id",
  "BeerFestDB::ORM::Company",
  { company_id => "company_id" },
);
__PACKAGE__->belongs_to(
  "product_id",
  "BeerFestDB::ORM::Product",
  { product_id => "product_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 00:22:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+Jo2mmKKWaF15KAjmdUQ+w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
