use utf8;
package BeerFestDB::ORM::Company;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::Company

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<company>

=cut

__PACKAGE__->table("company");

=head1 ACCESSORS

=head2 company_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 full_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 loc_desc

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 company_region_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 year_founded

  data_type: 'integer'
  is_nullable: 1

=head2 url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "company_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "full_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "loc_desc",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "company_region_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "year_founded",
  { data_type => "integer", is_nullable => 1 },
  "url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</company_id>

=back

=cut

__PACKAGE__->set_primary_key("company_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 company_region_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::CompanyRegion>

=cut

__PACKAGE__->belongs_to(
  "company_region_id",
  "BeerFestDB::ORM::CompanyRegion",
  { company_region_id => "company_region_id" },
);

=head2 contacts

Type: has_many

Related object: L<BeerFestDB::ORM::Contact>

=cut

__PACKAGE__->has_many(
  "contacts",
  "BeerFestDB::ORM::Contact",
  { "foreign.company_id" => "self.company_id" },
  {},
);

=head2 gyles

Type: has_many

Related object: L<BeerFestDB::ORM::Gyle>

=cut

__PACKAGE__->has_many(
  "gyles",
  "BeerFestDB::ORM::Gyle",
  { "foreign.company_id" => "self.company_id" },
  {},
);

=head2 product_orders

Type: has_many

Related object: L<BeerFestDB::ORM::ProductOrder>

=cut

__PACKAGE__->has_many(
  "product_orders",
  "BeerFestDB::ORM::ProductOrder",
  { "foreign.distributor_company_id" => "self.company_id" },
  {},
);

=head2 products

Type: has_many

Related object: L<BeerFestDB::ORM::Product>

=cut

__PACKAGE__->has_many(
  "products",
  "BeerFestDB::ORM::Product",
  { "foreign.company_id" => "self.company_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2013-02-26 21:06:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6LhSLOdCYR0a+bdJppQ2Kw


# You can replace this text with custom content, and it will be preserved on regeneration

1;
