package BeerFestDB::ORM::Currency;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("currency");
__PACKAGE__->add_columns(
  "currency_code",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 3 },
  "currency_number",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 3 },
  "currency_format",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "exponent",
  { data_type => "TINYINT", default_value => undef, is_nullable => 0, size => 4 },
  "currency_symbol",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
);
__PACKAGE__->set_primary_key("currency_code");
__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.currency_code" => "self.currency_code" },
);
__PACKAGE__->has_many(
  "festival_entries",
  "BeerFestDB::ORM::FestivalEntry",
  { "foreign.currency_code" => "self.currency_code" },
);
__PACKAGE__->has_many(
  "festival_products",
  "BeerFestDB::ORM::FestivalProduct",
  { "foreign.sale_currency_code" => "self.currency_code" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-05-16 20:35:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vi9cqWYjQC1A81J0w6DHKQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
