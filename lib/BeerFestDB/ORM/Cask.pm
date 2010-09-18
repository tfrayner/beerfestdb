package BeerFestDB::ORM::Cask;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::Cask

=cut

__PACKAGE__->table("cask");

=head1 ACCESSORS

=head2 cask_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 festival_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 gyle_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 distributor_company_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 container_size_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 bar_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 currency_code

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 3

=head2 price

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 stillage_location_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 stillage_bay

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 stillage_x_location

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 stillage_y_location

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 stillage_z_location

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 external_reference

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 internal_reference

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 is_vented

  data_type: 'tinyint'
  is_nullable: 1

=head2 is_tapped

  data_type: 'tinyint'
  is_nullable: 1

=head2 is_ready

  data_type: 'tinyint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cask_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "festival_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "gyle_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "distributor_company_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "container_size_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "bar_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "currency_code",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 3 },
  "price",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "stillage_location_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "stillage_bay",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "stillage_x_location",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "stillage_y_location",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "stillage_z_location",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "external_reference",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "internal_reference",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "is_vented",
  { data_type => "tinyint", is_nullable => 1 },
  "is_tapped",
  { data_type => "tinyint", is_nullable => 1 },
  "is_ready",
  { data_type => "tinyint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("cask_id");
__PACKAGE__->add_unique_constraint(
  "festival_gyle_cask",
  ["festival_id", "gyle_id", "internal_reference"],
);

=head1 RELATIONS

=head2 bar_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Bar>

=cut

__PACKAGE__->belongs_to("bar_id", "BeerFestDB::ORM::Bar", { bar_id => "bar_id" });

=head2 container_size_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ContainerSize>

=cut

__PACKAGE__->belongs_to(
  "container_size_id",
  "BeerFestDB::ORM::ContainerSize",
  { container_size_id => "container_size_id" },
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

=head2 distributor_company_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Company>

=cut

__PACKAGE__->belongs_to(
  "distributor_company_id",
  "BeerFestDB::ORM::Company",
  { company_id => "distributor_company_id" },
);

=head2 currency_code

Type: belongs_to

Related object: L<BeerFestDB::ORM::Currency>

=cut

__PACKAGE__->belongs_to(
  "currency_code",
  "BeerFestDB::ORM::Currency",
  { currency_code => "currency_code" },
);

=head2 gyle_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Gyle>

=cut

__PACKAGE__->belongs_to("gyle_id", "BeerFestDB::ORM::Gyle", { gyle_id => "gyle_id" });

=head2 stillage_location_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::StillageLocation>

=cut

__PACKAGE__->belongs_to(
  "stillage_location_id",
  "BeerFestDB::ORM::StillageLocation",
  { stillage_location_id => "stillage_location_id" },
);

=head2 cask_measurements

Type: has_many

Related object: L<BeerFestDB::ORM::CaskMeasurement>

=cut

__PACKAGE__->has_many(
  "cask_measurements",
  "BeerFestDB::ORM::CaskMeasurement",
  { "foreign.cask_id" => "self.cask_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-09-18 15:42:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V0zLwF9TIZR0jMDbkfMevA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
