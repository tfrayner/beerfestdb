use utf8;
package BeerFestDB::ORM::DispenseMethod;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::DispenseMethod

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<dispense_method>

=cut

__PACKAGE__->table("dispense_method");

=head1 ACCESSORS

=head2 dispense_method_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "dispense_method_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</dispense_method_id>

=back

=cut

__PACKAGE__->set_primary_key("dispense_method_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<description>

=over 4

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 container_sizes

Type: has_many

Related object: L<BeerFestDB::ORM::ContainerSize>

=cut

__PACKAGE__->has_many(
  "container_sizes",
  "BeerFestDB::ORM::ContainerSize",
  { "foreign.dispense_method_id" => "self.dispense_method_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-04-04 18:03:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MOArNBdg0Ckz+C0bV3yB6w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
sub repr {
    my ( $self ) = @_; return $self->description;
}

1;
