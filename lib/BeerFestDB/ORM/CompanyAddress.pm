package BeerFestDB::ORM::CompanyAddress;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("company_address");
__PACKAGE__->add_columns(
  "company",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "address",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
);
__PACKAGE__->set_primary_key("company", "address");
__PACKAGE__->belongs_to("company", "BeerFestDB::ORM::Company", { id => "company" });
__PACKAGE__->belongs_to("address", "BeerFestDB::ORM::Address", { id => "address" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-01-25 16:03:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZM45Iu37Ma0GnLPLbdnnlA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
