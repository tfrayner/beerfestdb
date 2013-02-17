use utf8;
package BeerFestDB::ORM::MeasurementBatch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::MeasurementBatch

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<measurement_batch>

=cut

__PACKAGE__->table("measurement_batch");

=head1 ACCESSORS

=head2 measurement_batch_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 festival_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 measurement_time

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "measurement_batch_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "festival_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "measurement_time",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</measurement_batch_id>

=back

=cut

__PACKAGE__->set_primary_key("measurement_batch_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<festival_measurement_batch>

=over 4

=item * L</festival_id>

=item * L</measurement_time>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "festival_measurement_batch",
  ["festival_id", "measurement_time"],
);

=head1 RELATIONS

=head2 cask_measurements

Type: has_many

Related object: L<BeerFestDB::ORM::CaskMeasurement>

=cut

__PACKAGE__->has_many(
  "cask_measurements",
  "BeerFestDB::ORM::CaskMeasurement",
  { "foreign.measurement_batch_id" => "self.measurement_batch_id" },
  {},
);

=head2 festival_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Festival>

=cut

__PACKAGE__->belongs_to(
  "festival_id",
  "BeerFestDB::ORM::Festival",
  { festival_id => "festival_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-03-22 16:57:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ww9nUpHUxgL0fdqHRLFhlQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
