use utf8;
package BeerFestDB::ORM::CaskMeasurement;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::CaskMeasurement

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cask_measurement>

=cut

__PACKAGE__->table("cask_measurement");

=head1 ACCESSORS

=head2 cask_measurement_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 cask_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 measurement_batch_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 volume

  data_type: 'decimal'
  is_nullable: 0
  size: [5,2]

=head2 container_measure_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cask_measurement_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "cask_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "measurement_batch_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "volume",
  { data_type => "decimal", is_nullable => 0, size => [5, 2] },
  "container_measure_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cask_measurement_id>

=back

=cut

__PACKAGE__->set_primary_key("cask_measurement_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cask_measurement_batch>

=over 4

=item * L</cask_id>

=item * L</measurement_batch_id>

=back

=cut

__PACKAGE__->add_unique_constraint("cask_measurement_batch", ["cask_id", "measurement_batch_id"]);

=head1 RELATIONS

=head2 cask_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Cask>

=cut

__PACKAGE__->belongs_to("cask_id", "BeerFestDB::ORM::Cask", { cask_id => "cask_id" });

=head2 container_measure_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ContainerMeasure>

=cut

__PACKAGE__->belongs_to(
  "container_measure_id",
  "BeerFestDB::ORM::ContainerMeasure",
  { container_measure_id => "container_measure_id" },
);

=head2 measurement_batch_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::MeasurementBatch>

=cut

__PACKAGE__->belongs_to(
  "measurement_batch_id",
  "BeerFestDB::ORM::MeasurementBatch",
  { measurement_batch_id => "measurement_batch_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-03-22 16:57:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OhLE6jWkewRdIwEBF9//6A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
