package BeerFestDB::ORM::CaskSalePrice;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cask_sale_price");
__PACKAGE__->add_columns(
  "cask_sale_price_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "cask_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 6 },
  "sale_volume_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 3 },
  "currency_code",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 3 },
  "sale_price",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "valid",
  { data_type => "BIT", default_value => undef, is_nullable => 1, size => undef },
);
__PACKAGE__->set_primary_key("cask_sale_price_id");
__PACKAGE__->belongs_to("cask_id", "BeerFestDB::ORM::Cask", { cask_id => "cask_id" });
__PACKAGE__->belongs_to(
  "sale_volume_id",
  "BeerFestDB::ORM::SaleVolume",
  { sale_volume_id => "sale_volume_id" },
);
__PACKAGE__->belongs_to(
  "currency_code",
  "BeerFestDB::ORM::Currency",
  { currency_code => "currency_code" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-06 12:24:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Hs1/QX9zVZf4OBAwlpXeSQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
