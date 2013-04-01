drop table if exists cask_management;
create table cask_management (
  cask_management_id INTEGER(6) NOT NULL AUTO_INCREMENT,
  festival_id INTEGER(6) NOT NULL,
  distributor_company_id INTEGER(6) NULL,
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
  is_sale_or_return TINYINT(1) NULL,
  PRIMARY KEY(cask_management_id),
--  UNIQUE KEY `festival_gyle_cask` (festival_id, gyle_id, internal_reference),
  UNIQUE KEY `festival_cellar_ref` (festival_id, cellar_reference),
  INDEX IDX_CSKMAN_dfid(distributor_company_id),
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
  FOREIGN KEY FK_CSKMAN_dcId_COMP_compid(distributor_company_id)
    REFERENCES company(company_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSKMAN_poId_COMP_poid(product_order_id)
    REFERENCES product_order(product_order_id)
      ON DELETE CASCADE -- prevents inadvertent cask_management orphanage.
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
  `distributor_company_id`,
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
  `cellar_reference`,
  `is_sale_or_return`
) select
  cask_id,
  festival_id,
  distributor_company_id,
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
  cellar_reference,
  is_sale_or_return from cask;

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
-- This loses data, but it's data we've never used, and in it's place
-- we get a more granular record of differences between order and
-- delivery.
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
alter table cask drop column is_sale_or_return;


delimiter //

-- Festival to Product to Cask
-- Check inserts, updates on cask table (note that we also check updates on Gyle below).
drop trigger if exists `cask_fp_insert_trigger`
//
create trigger `cask_fp_insert_trigger`
    before insert on cask
for each row
begin
    -- check that the gyle is valid
    if ( (select count(fp.festival_id)
            from festival_product fp, gyle g, cask_management cg
            where new.gyle_id=g.gyle_id
            and g.festival_product_id=fp.festival_product_id
            and fp.festival_id=cg.festival_id
            and cg.cask_management_id=new.cask_management_id) = 0 ) then
        call ERROR_CASK_FP_INSERT_TRIGGER();
    end if;
    -- check that the order_batch is valid
    if (  -- the linked cask_management has a product_order_id
         (select count(cg.cask_management_id)
            from cask_management cg
            where cg.cask_management_id=new.cask_management_id
            and cg.product_order_id is not null) = 1
       and -- the product_order_id belongs to the right festival.
         (select count(ob.order_batch_id)
            from cask_management cg, product_order po, order_batch ob
            where ob.festival_id=cg.festival_id
            and cg.cask_management_id=new.cask_management_id
            and po.order_batch_id=ob.order_batch_id
            and cg.product_order_id=po.product_order_id) = 0 ) then
        call ERROR_CASK_OB_INSERT_TRIGGER();
    end if;
end;
//

drop trigger if exists `cask_update_trigger`
//
create trigger `cask_update_trigger`
    before update on cask
for each row
begin
    if ( (select count(fp.festival_id)
            from festival_product fp, gyle g, cask_management cg
            where new.gyle_id=g.gyle_id
            and g.festival_product_id=fp.festival_product_id
            and fp.festival_id=cg.festival_id
            and cg.cask_management_id=new.cask_management_id) = 0 ) then
        call ERROR_CASK_FP_UPDATE_TRIGGER();
    end if;
end;
//

drop trigger if exists `gyle_fp_update_trigger`
//
create trigger `gyle_fp_update_trigger`
    before update on gyle
for each row
begin
    if ( new.festival_product_id != old.festival_product_id and
           (select count(fp.festival_id)
            from festival_product fp, cask c, cask_management cg
            where old.gyle_id=c.gyle_id
            and c.cask_management_id=cg.cask_management_id
            and cg.festival_id=fp.festival_id
            and fp.festival_product_id=old.festival_product_id) != 0 ) then
        call ERROR_GYLE_FP_UPDATE_TRIGGER();
    end if;
end;
//

drop trigger if exists `fp_cask_update_trigger`
//
create trigger `fp_cask_update_trigger`
    before update on festival_product
for each row
begin
    if (  new.festival_id != old.festival_id and
         (select count(f.festival_id)
          from festival f, gyle g, cask c, cask_management cg
          where old.festival_id=cg.festival_id
          and cg.cask_management_id=c.cask_management_id
          and c.gyle_id=g.gyle_id
          and g.festival_product_id=old.festival_product_id) != 0 ) then
        call ERROR_FP_CASK_UPDATE_TRIGGER();
    end if;
end;
//

-- We need cask_management update triggers (insert creates no cycles,
-- and delete breaks the cycles, so a trigger is not needed in either
-- of these cases).
drop trigger if exists `cask_management_update_trigger`
//
create trigger `cask_management_update_trigger`
    before update on cask_management
for each row
begin
    -- check that the product_order is valid
    if ( new.product_order_id is not null
        and new.product_order_id != old.product_order_id
        and (select count(ob.order_batch_id)
             from product_order po, order_batch ob
             where new.product_order_id=po.product_order_id
             and po.order_batch_id=ob.order_batch_id
             and ob.festival_id=new.festival_id) = 0 ) then
        call ERROR_CASKMAN_OB_UPDATE_TRIGGER();
    end if;
    if ( new.festival_id != old.festival_id and
           (select count(cm.cask_id)
            from cask c, cask_measurement cm, measurement_batch mb, cask_management cg
            where old.festival_id=mb.festival_id
            and cm.measurement_batch_id=mb.measurement_batch_id
            and c.cask_id=cm.cask_id
            and c.cask_management_id=old.cask_management_id) != 0 ) then
        call ERROR_CASKMAN_MB_UPDATE_TRIGGER();
    end if;
end;
//

-- FestivalProduct to (Cask and MeasurementBatch) to CaskMeasurement

-- Check inserts, updates on cask_measurement table
drop trigger if exists `cask_measurement_insert_trigger`
//
create trigger `cask_measurement_insert_trigger`
    before insert on cask_measurement
for each row
begin
    if ( (select count(mb.measurement_batch_id)
            from cask c, measurement_batch mb, cask_management cg
            where new.cask_id=c.cask_id
            and c.cask_management_id=cg.cask_management_id
            and mb.festival_id=cg.festival_id
            and mb.measurement_batch_id=new.measurement_batch_id) = 0 ) then
        call ERROR_CASK_MEASUREMENT_INSERT_TRIGGER();
    end if;
end;
//

drop trigger if exists `cask_measurement_update_trigger`
//
create trigger `cask_measurement_update_trigger`
    before update on cask_measurement
for each row
begin
    if ( (select count(mb.measurement_batch_id)
            from cask c, measurement_batch mb, cask_management cg
            where new.cask_id=c.cask_id
            and c.cask_management_id=cg.cask_management_id
            and mb.festival_id=cg.festival_id
            and mb.measurement_batch_id=new.measurement_batch_id) = 0 ) then
        call ERROR_CASK_MEASUREMENT_UPDATE_TRIGGER();
    end if;
end;
//

drop trigger if exists `measurement_batch_update_trigger`
//
create trigger `measurement_batch_update_trigger`
    before update on measurement_batch
for each row
begin
    if ( new.festival_id != old.festival_id and
           (select count(cm.measurement_batch_id)
            from cask_measurement cm, cask c, cask_management cg
            where old.measurement_batch_id=cm.measurement_batch_id
            and cm.cask_id=c.cask_id
            and cg.cask_manegement_id=c.cask_management_id
            and cg.festival_id=old.festival_id) != 0 ) then
        call ERROR_MEASUREMENT_BATCH_UPDATE_TRIGGER();
    end if;
end;
//

-- Order Batch
drop trigger if exists `order_batch_update_trigger`
//
create trigger `order_batch_update_trigger`
    before update on order_batch
for each row
begin
    -- if we're changing festival association, ensure we haven't
    -- already used this batch elsewhere.
    if ( old.festival_id != new.festival_id
         and (select count(c.order_batch_id)
              from cask c, cask_management cg, product_order po
              where c.cask_management_id=cg.cask_management_id
              and cg.product_order_id=po.product_order_id
              and po.order_batch_id=old.order_batch_id
              ) > 0 ) then
        call ERROR_ORDER_BATCH_UPDATE_TRIGGER();
    end if;
end;
//

-- End of triggers
delimiter ;

