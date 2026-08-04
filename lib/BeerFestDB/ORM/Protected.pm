use utf8;
package BeerFestDB::ORM::Protected;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("protected");

__PACKAGE__->add_columns(
  "protected_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "classname",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "loader",
  { data_type => "tinyint", default_value => 0, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("protected_id");

__PACKAGE__->add_unique_constraint("classname", ["classname"]);

sub repr {
    my ($self) = @_;
    return $self->classname;
}

1;
