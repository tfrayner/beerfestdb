ALTER TABLE container_measure ADD COLUMN `symbol` varchar(16) default NULL;

update container_measure set symbol='L' where description='litre';
update container_measure set symbol='gal' where description='gallon';
update container_measure set symbol='pt' where description='pint';
update container_measure set symbol='hp' where description='half pint';
update container_measure set symbol='btl' where description='500ml bottle';
update container_measure set symbol='gls' where description='175ml glass';
update container_measure set symbol='btl' where description='75cl bottle';

ALTER TABLE container_measure MODIFY COLUMN `symbol` varchar(16) NOT NULL;
