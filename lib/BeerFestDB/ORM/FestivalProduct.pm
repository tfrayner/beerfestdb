package BeerFestDB::ORM::FestivalProduct;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("festival_product");
__PACKAGE__->add_columns(
  "festival_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "product_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
);
__PACKAGE__->set_primary_key("festival_id", "product_id");
__PACKAGE__->belongs_to(
  "festival_id",
  "BeerFestDB::ORM::Festival",
  { festival_id => "festival_id" },
);
__PACKAGE__->belongs_to(
  "product_id",
  "BeerFestDB::ORM::Product",
  { product_id => "product_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-05-02 20:33:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4E1sb2EartdfodztduWiLw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
