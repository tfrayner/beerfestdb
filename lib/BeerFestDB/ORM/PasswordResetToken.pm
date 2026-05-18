use utf8;
package BeerFestDB::ORM::PasswordResetToken;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("password_reset_token");

__PACKAGE__->add_columns(
  "token_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_nullable => 0 },
  "token_hash",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "expires_at",
  { data_type => "datetime", is_nullable => 0 },
  "used",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "created_at",
  { data_type => "datetime", is_nullable => 0, default_value => \"CURRENT_TIMESTAMP" },
);

__PACKAGE__->set_primary_key("token_id");

__PACKAGE__->add_unique_constraint("token_hash", ["token_hash"]);

__PACKAGE__->belongs_to(
  "user",
  "BeerFestDB::ORM::User",
  { "foreign.user_id" => "self.user_id" },
);

1;
