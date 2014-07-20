use utf8;
package BeerFestDB::ORM::CompanyRegion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::CompanyRegion

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<company_region>

=cut

__PACKAGE__->table("company_region");

=head1 ACCESSORS

=head2 company_region_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "company_region_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 30 },
);

=head1 PRIMARY KEY

=over 4

=item * L</company_region_id>

=back

=cut

__PACKAGE__->set_primary_key("company_region_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<description>

=over 4

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 companies

Type: has_many

Related object: L<BeerFestDB::ORM::Company>

=cut

__PACKAGE__->has_many(
  "companies",
  "BeerFestDB::ORM::Company",
  { "foreign.company_region_id" => "self.company_region_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-20 17:33:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7wEWMRTBe6VifAWH1oSRVw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
