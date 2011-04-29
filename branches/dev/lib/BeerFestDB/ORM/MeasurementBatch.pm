package BeerFestDB::ORM::MeasurementBatch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::MeasurementBatch

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

=cut

__PACKAGE__->add_columns(
  "measurement_batch_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "festival_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "measurement_time",
  {
    data_type => "datetime",
    "datetime_undef_if_invalid" => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("measurement_batch_id");
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-04-29 21:03:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e2kJuyjky6GHvFaXK0hGKQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
