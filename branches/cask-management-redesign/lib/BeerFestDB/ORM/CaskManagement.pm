use utf8;
package BeerFestDB::ORM::CaskManagement;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::CaskManagement

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cask_management>

=cut

__PACKAGE__->table("cask_management");

=head1 ACCESSORS

=head2 cask_management_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 festival_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 distributor_company_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 product_order_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 container_size_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 bar_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 currency_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

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

=head2 bay_position_id

  data_type: 'integer'
  is_foreign_key: 1
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

=head2 internal_reference

  data_type: 'integer'
  is_nullable: 1

=head2 cellar_reference

  data_type: 'integer'
  is_nullable: 1

=head2 is_sale_or_return

  data_type: 'tinyint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cask_management_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "festival_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "distributor_company_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "product_order_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "container_size_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "bar_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "currency_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "price",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "stillage_location_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "stillage_bay",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "bay_position_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "stillage_x_location",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "stillage_y_location",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "stillage_z_location",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "internal_reference",
  { data_type => "integer", is_nullable => 1 },
  "cellar_reference",
  { data_type => "integer", is_nullable => 1 },
  "is_sale_or_return",
  { data_type => "tinyint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cask_management_id>

=back

=cut

__PACKAGE__->set_primary_key("cask_management_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<festival_cellar_ref>

=over 4

=item * L</festival_id>

=item * L</cellar_reference>

=back

=cut

__PACKAGE__->add_unique_constraint("festival_cellar_ref", ["festival_id", "cellar_reference"]);

=head1 RELATIONS

=head2 bar_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Bar>

=cut

__PACKAGE__->belongs_to("bar_id", "BeerFestDB::ORM::Bar", { bar_id => "bar_id" });

=head2 bay_position_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::BayPosition>

=cut

__PACKAGE__->belongs_to(
  "bay_position_id",
  "BeerFestDB::ORM::BayPosition",
  { bay_position_id => "bay_position_id" },
);

=head2 casks

Type: has_many

Related object: L<BeerFestDB::ORM::Cask>

=cut

__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.cask_management_id" => "self.cask_management_id" },
  {},
);

=head2 container_size_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ContainerSize>

=cut

__PACKAGE__->belongs_to(
  "container_size_id",
  "BeerFestDB::ORM::ContainerSize",
  { container_size_id => "container_size_id" },
);

=head2 currency_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Currency>

=cut

__PACKAGE__->belongs_to(
  "currency_id",
  "BeerFestDB::ORM::Currency",
  { currency_id => "currency_id" },
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

=head2 festival_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Festival>

=cut

__PACKAGE__->belongs_to(
  "festival_id",
  "BeerFestDB::ORM::Festival",
  { festival_id => "festival_id" },
);

=head2 product_order_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ProductOrder>

=cut

__PACKAGE__->belongs_to(
  "product_order_id",
  "BeerFestDB::ORM::ProductOrder",
  { product_order_id => "product_order_id" },
);

=head2 stillage_location_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::StillageLocation>

=cut

__PACKAGE__->belongs_to(
  "stillage_location_id",
  "BeerFestDB::ORM::StillageLocation",
  { stillage_location_id => "stillage_location_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2013-03-03 22:25:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xcsVwXLh+HCPXp1CV+s8pQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
