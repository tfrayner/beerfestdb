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
  "country_code_iso2",
  { data_type => "char", is_nullable => 0, size => 2 },
  "country_code_iso3",
  { data_type => "char", is_nullable => 0, size => 3 },
  "country_code_num3",
  { data_type => "char", is_nullable => 0, size => 3 },
  "country_name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);
__PACKAGE__->set_primary_key("country_code_iso2");

=head1 RELATIONS

=head2 contacts

Type: has_many

Related object: L<BeerFestDB::ORM::Contact>

=cut

__PACKAGE__->has_many(
  "contacts",
  "BeerFestDB::ORM::Contact",
  { "foreign.country_code_iso2" => "self.country_code_iso2" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uXPfhEZhGbRkjknUSmhK7A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
