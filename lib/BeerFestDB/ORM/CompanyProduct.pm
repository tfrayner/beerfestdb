package BeerFestDB::ORM::CompanyProduct;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("company_product");
__PACKAGE__->add_columns(
  "company_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "product_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
);
__PACKAGE__->set_primary_key("company_id", "product_id");
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


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-05-02 20:33:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4A2f9Lgweo09ldCMZ+k2yw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
