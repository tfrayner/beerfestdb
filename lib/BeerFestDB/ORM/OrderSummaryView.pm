use utf8;
package BeerFestDB::ORM::OrderSummaryView;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::OrderSummaryView - VIEW

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<order_summary_view>

=cut

__PACKAGE__->table("order_summary_view");
__PACKAGE__->result_source_instance->view_definition("(select `f`.`name` AS `festival`,`pc`.`description` AS `category`,`c`.`name` AS `brewery`,`p`.`name` AS `beer`,`st`.`description` AS `style`,if((`po`.`is_sale_or_return` = 1),'Yes','No') AS `sale_or_return`,`p`.`nominal_abv` AS `abv`,round(sum((((`po`.`cask_count` * `cs`.`container_volume`) * `cm`.`litre_multiplier`) / (18 * 4.5461))),1) AS `kils` from (((((((`beerfestdb`.`company` `c` join `beerfestdb`.`product_category` `pc`) join (`beerfestdb`.`product` `p` left join `beerfestdb`.`product_style` `st` on((`p`.`product_style_id` = `st`.`product_style_id`)))) join `beerfestdb`.`product_order` `po`) join `beerfestdb`.`order_batch` `ob`) join `beerfestdb`.`container_size` `cs`) join `beerfestdb`.`container_measure` `cm`) join `beerfestdb`.`festival` `f`) where ((`f`.`festival_id` = `ob`.`festival_id`) and (`ob`.`order_batch_id` = `po`.`order_batch_id`) and (`p`.`product_id` = `po`.`product_id`) and (`p`.`company_id` = `c`.`company_id`) and (`po`.`container_size_id` = `cs`.`container_size_id`) and (`cs`.`container_measure_id` = `cm`.`container_measure_id`) and (`p`.`product_category_id` = `pc`.`product_category_id`) and (`po`.`is_final` = 1)) group by `f`.`name`,`pc`.`description`,`c`.`name`,`p`.`name`,`st`.`description`,if((`po`.`is_sale_or_return` = 1),'Yes','No'),`p`.`nominal_abv`,((`po`.`cask_count` * `cs`.`container_volume`) * `cm`.`litre_multiplier`))");

=head1 ACCESSORS

=head2 festival

  data_type: 'varchar'
  is_nullable: 0
  size: 60

=head2 category

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 brewery

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 beer

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 style

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 sale_or_return

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 3

=head2 abv

  data_type: 'decimal'
  is_nullable: 1
  size: [3,1]

=head2 kils

  data_type: 'decimal'
  is_nullable: 1
  size: [43,1]

=cut

__PACKAGE__->add_columns(
  "festival",
  { data_type => "varchar", is_nullable => 0, size => 60 },
  "category",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "brewery",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "beer",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "style",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "sale_or_return",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 3 },
  "abv",
  { data_type => "decimal", is_nullable => 1, size => [3, 1] },
  "kils",
  { data_type => "decimal", is_nullable => 1, size => [43, 1] },
);


# Created by DBIx::Class::Schema::Loader v0.07048 @ 2020-05-11 19:15:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Bhf0DWwSwPKn2By63xw4kg

__PACKAGE__->result_source_instance->is_virtual(1);

1;
