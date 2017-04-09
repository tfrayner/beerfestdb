use utf8;
package BeerFestDB::ORM::SaleVolume;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::SaleVolume

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sale_volume>

=cut

__PACKAGE__->table("sale_volume");

=head1 ACCESSORS

=head2 sale_volume_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 container_measure_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 volume

  data_type: 'decimal'
  is_nullable: 1
  size: [4,2]

=cut

__PACKAGE__->add_columns(
  "sale_volume_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "container_measure_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "volume",
  { data_type => "decimal", is_nullable => 1, size => [4, 2] },
);

=head1 PRIMARY KEY

=over 4

=item * L</sale_volume_id>

=back

=cut

__PACKAGE__->set_primary_key("sale_volume_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<description>

=over 4

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 container_measure_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ContainerMeasure>

=cut

__PACKAGE__->belongs_to(
  "container_measure_id",
  "BeerFestDB::ORM::ContainerMeasure",
  { container_measure_id => "container_measure_id" },
);

=head2 festival_products

Type: has_many

Related object: L<BeerFestDB::ORM::FestivalProduct>

=cut

__PACKAGE__->has_many(
  "festival_products",
  "BeerFestDB::ORM::FestivalProduct",
  { "foreign.sale_volume_id" => "self.sale_volume_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-20 17:33:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e2xxg05sszJfuw2EK9mUrg


# You can replace this text with custom content, and it will be preserved on regeneration
sub repr {
    my ( $self ) = @_; return $self->description;
}

1;
