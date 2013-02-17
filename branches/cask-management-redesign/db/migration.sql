drop table if exists cask_management;
create table cask_management (
  cask_management_id INTEGER(6) NOT NULL AUTO_INCREMENT,
  festival_id INTEGER(6) NOT NULL,
--  distributor_company_id INTEGER(6) NULL,
--  order_batch_id INTEGER(6) NULL,
  product_order_id INTEGER(6) NULL,
  container_size_id INTEGER(6) NOT NULL,
  bar_id INTEGER(6) NULL,
  currency_id INTEGER(6) NOT NULL,
  price INTEGER(11) UNSIGNED NULL,
  stillage_location_id INTEGER(6) NULL,
  stillage_bay INTEGER(4) UNSIGNED NULL,
  bay_position_id INTEGER(6) NULL,
  stillage_x_location INTEGER(6) UNSIGNED NULL,
  stillage_y_location INTEGER(6) UNSIGNED NULL,
  stillage_z_location INTEGER(6) UNSIGNED NULL,
  internal_reference INTEGER(6) NULL,
  cellar_reference INTEGER(6) NULL,
  PRIMARY KEY(cask_management_id),
--  UNIQUE KEY `festival_gyle_cask` (festival_id, gyle_id, internal_reference),
  UNIQUE KEY `festival_cellar_ref` (festival_id, cellar_reference),
  INDEX IDX_CSKMAN_poid(product_order_id),
  INDEX IDX_CSKMAN_bid(bar_id),
  INDEX IDX_CSKMAN_stid(stillage_location_id),
  INDEX IDX_CSKMAN_bpid(bay_position_id),
  INDEX IDX_CSKMAN_csid_CS_csid(container_size_id),
  INDEX IDX_CSKMAN_cc3_CUR_cc3(currency_id),
  INDEX IDX_CSKMAN_iref(internal_reference),
  FOREIGN KEY FK_CSKMAN_bid_BR_bid(bar_id)
    REFERENCES bar(bar_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSKMAN_csid_CS_csid(container_size_id)
    REFERENCES container_size(container_size_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSKMAN_fstId_FST_fstid(festival_id)
    REFERENCES festival(festival_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSKMAN_poId_COMP_poid(product_order_id)
    REFERENCES product_order(product_order_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSKMAN_curcd_CUR_curcd(currency_id)
    REFERENCES currency(currency_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSKMAN_locid_BAYPOS_locid(bay_position_id)
    REFERENCES bay_position(bay_position_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSKMAN_locid_STILLOC_locid(stillage_location_id)
    REFERENCES stillage_location(stillage_location_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
ENGINE=InnoDB DEFAULT CHARSET=utf8;

insert into cask_management (
  `cask_management_id`,
  `festival_id`,
  `container_size_id`,
  `bar_id`,
  `currency_id`,
  `price`,
  `stillage_location_id`,
  `stillage_bay`,
  `bay_position_id`,
  `stillage_x_location`,
  `stillage_y_location`,
  `stillage_z_location`,
  `internal_reference`,
  `cellar_reference`
) select
  cask_id,
  festival_id,
  container_size_id,
  bar_id,
  currency_id,
  price,
  stillage_location_id,
  stillage_bay,
  bay_position_id,
  stillage_x_location,
  stillage_y_location,
  stillage_z_location,
  internal_reference,
  cellar_reference from cask;

alter table cask add column cask_management_id integer(6);
update cask set cask_management_id=cask_id;
alter table cask modify column cask_management_id integer(6) NOT NULL;
alter table cask add constraint UNIQUE KEY `cask_management` (cask_management_id);
alter table cask add constraint foreign key
  FK_CSK_cskmanid_CSKMAN_cskmanid(cask_management_id)
    REFERENCES cask_management(cask_management_id)
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

alter table cask drop FOREIGN KEY `cask_ibfk_1`;
alter table cask drop FOREIGN KEY `cask_ibfk_2`;
alter table cask drop FOREIGN KEY `cask_ibfk_3`;
alter table cask drop FOREIGN KEY `cask_ibfk_4`;
alter table cask drop FOREIGN KEY `cask_ibfk_8`;
alter table cask drop FOREIGN KEY `cask_ibfk_5`;
alter table cask drop FOREIGN KEY `cask_ibfk_9`;
alter table cask drop FOREIGN KEY `cask_ibfk_7`;


alter table cask drop KEY `festival_gyle_cask`;
alter table cask drop KEY `festival_cellar_ref`;
alter table cask drop INDEX FK_CSK_dcid;
alter table cask drop INDEX FK_CSK_obid;
alter table cask drop INDEX FK_CSK_bid;
alter table cask drop INDEX FK_CSK_stid;
alter table cask drop INDEX FK_CSK_bpid;
alter table cask drop INDEX FK_CSK_csid_CS_csid;
alter table cask drop INDEX FK_CSK_cc3_CUR_cc3;
alter table cask drop INDEX IDX_CSK_exref;

alter table cask drop column festival_id;
alter table cask drop column distributor_company_id;
alter table cask drop column order_batch_id;
alter table cask drop column container_size_id;
alter table cask drop column bar_id;
alter table cask drop column currency_id;
alter table cask drop column price;
alter table cask drop column stillage_location_id;
alter table cask drop column stillage_bay;
alter table cask drop column bay_position_id;
alter table cask drop column stillage_x_location;
alter table cask drop column stillage_y_location;
alter table cask drop column stillage_z_location;
alter table cask drop column internal_reference;
alter table cask drop column cellar_reference;
