use utf8;
package BeerFestDB::ORM::ProgrammeNotesView;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::ProgrammeNotesView - VIEW

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<programme_notes_view>

=cut

__PACKAGE__->table("programme_notes_view");
__PACKAGE__->result_source_instance->view_definition("(select distinct `f`.`name` AS `festival`,`pc`.`description` AS `category`,`c`.`name` AS `brewer`,`c`.`loc_desc` AS `location`,`c`.`year_founded` AS `year_established`,`p`.`name` AS `beer`,`p`.`nominal_abv` AS `abv`,`p`.`description` AS `tasting_notes`,`p`.`long_description` AS `tasting_essay`,`ps`.`description` AS `style`,`dm`.`description` AS `dispense_method` from (((((((`beerfestdb`.`company` `c` join (`beerfestdb`.`product` `p` left join `beerfestdb`.`product_style` `ps` on((`ps`.`product_style_id` = `p`.`product_style_id`)))) join `beerfestdb`.`product_category` `pc`) join `beerfestdb`.`product_order` `po`) join `beerfestdb`.`order_batch` `ob`) join `beerfestdb`.`festival` `f`) join `beerfestdb`.`container_size` `cs`) join `beerfestdb`.`dispense_method` `dm`) where ((`f`.`festival_id` = `ob`.`festival_id`) and (`ob`.`order_batch_id` = `po`.`order_batch_id`) and (`po`.`product_id` = `p`.`product_id`) and (`p`.`company_id` = `c`.`company_id`) and (`pc`.`product_category_id` = `p`.`product_category_id`) and (`po`.`container_size_id` = `cs`.`container_size_id`) and (`cs`.`dispense_method_id` = `dm`.`dispense_method_id`) and (`po`.`is_final` = 1)) order by `f`.`name`,`pc`.`description`,`c`.`name`,`p`.`name`,`dm`.`description`)");

=head1 ACCESSORS

=head2 festival

  data_type: 'varchar'
  is_nullable: 0
  size: 60

=head2 category

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 brewer

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 location

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 year_established

  data_type: 'integer'
  is_nullable: 1

=head2 beer

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 abv

  data_type: 'decimal'
  is_nullable: 1
  size: [3,1]

=head2 tasting_notes

  data_type: 'text'
  is_nullable: 1

=head2 tasting_essay

  data_type: 'text'
  is_nullable: 1

=head2 style

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 dispense_method

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "festival",
  { data_type => "varchar", is_nullable => 0, size => 60 },
  "category",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "brewer",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "location",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "year_established",
  { data_type => "integer", is_nullable => 1 },
  "beer",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "abv",
  { data_type => "decimal", is_nullable => 1, size => [3, 1] },
  "tasting_notes",
  { data_type => "text", is_nullable => 1 },
  "tasting_essay",
  { data_type => "text", is_nullable => 1 },
  "style",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "dispense_method",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);


# Created by DBIx::Class::Schema::Loader v0.07048 @ 2020-05-11 19:15:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qqHvvcy995iGygUWOTrWOA

__PACKAGE__->result_source_instance->is_virtual(1);

1;
