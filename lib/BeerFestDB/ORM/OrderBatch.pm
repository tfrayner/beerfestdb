use utf8;
package BeerFestDB::ORM::OrderBatch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::OrderBatch

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<order_batch>

=cut

__PACKAGE__->table("order_batch");

=head1 ACCESSORS

=head2 order_batch_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 festival_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 order_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "order_batch_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "festival_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "order_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</order_batch_id>

=back

=cut

__PACKAGE__->set_primary_key("order_batch_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<festival_order_batch>

=over 4

=item * L</festival_id>

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("festival_order_batch", ["festival_id", "description"]);

=head1 RELATIONS

=head2 festival_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Festival>

=cut

__PACKAGE__->belongs_to(
  "festival_id",
  "BeerFestDB::ORM::Festival",
  { festival_id => "festival_id" },
);

=head2 product_orders

Type: has_many

Related object: L<BeerFestDB::ORM::ProductOrder>

=cut

__PACKAGE__->has_many(
  "product_orders",
  "BeerFestDB::ORM::ProductOrder",
  { "foreign.order_batch_id" => "self.order_batch_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-20 17:33:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2RyJ9qpoOVZZk7WLnxfr4g


# You can replace this text with custom content, and it will be preserved on regeneration
sub repr {
    my ( $self ) = @_; return sprintf("%s: %s",
				      $self->festival_id->repr(),
				      $self->description);
}

1;
