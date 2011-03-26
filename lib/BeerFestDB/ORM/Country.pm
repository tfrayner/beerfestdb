package BeerFestDB::ORM::Country;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::Country

=cut

__PACKAGE__->table("country");

=head1 ACCESSORS

=head2 country_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 country_code_iso2

  data_type: 'char'
  is_nullable: 0
  size: 2

=head2 country_code_iso3

  data_type: 'char'
  is_nullable: 0
  size: 3

=head2 country_code_num3

  data_type: 'char'
  is_nullable: 0
  size: 3

=head2 country_name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "country_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "country_code_iso2",
  { data_type => "char", is_nullable => 0, size => 2 },
  "country_code_iso3",
  { data_type => "char", is_nullable => 0, size => 3 },
  "country_code_num3",
  { data_type => "char", is_nullable => 0, size => 3 },
  "country_name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);
__PACKAGE__->set_primary_key("country_id");

=head1 RELATIONS

=head2 contacts

Type: has_many

Related object: L<BeerFestDB::ORM::Contact>

=cut

__PACKAGE__->has_many(
  "contacts",
  "BeerFestDB::ORM::Contact",
  { "foreign.country_id" => "self.country_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-26 11:41:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2LJqbojLB/zErqsS3LTM7w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
