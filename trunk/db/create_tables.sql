drop table if exists address;
create table address
  (addr_id INTEGER(6) AUTO_INCREMENT not null PRIMARY KEY,
   street_address VARCHAR(255),
   postcode VARCHAR(10),
   email VARCHAR(100) null,
   phone_no VARCHAR(15) null,
   fax_no VARCHAR(15) null,
   comment VARCHAR(255) null);

drop table if exists beer;
create table beer
  (beer_id INTEGER(6) AUTO_INCREMENT not null PRIMARY KEY,
   name VARCHAR(100) not null,
   style VARCHAR(20) null,
   description TEXT null,
   comment VARCHAR(255) null);

drop table if exists company;
create table company
  (co_id INTEGER(6) AUTO_INCREMENT not null PRIMARY KEY,
   name VARCHAR(100) not null,
   loc_desc VARCHAR(100) null,
   year_founded VARCHAR(12) null,
   comment VARCHAR(255) null);

drop table if exists gyle;
create table gyle
  (gyle_id INTEGER(6) AUTO_INCREMENT not null PRIMARY KEY,
   external_id VARCHAR(10) null,
   brewer INTEGER(6) not null,
     foreign key (brewer) references company (co_id),
   beer INTEGER(6) not null,
     foreign key (beer) references beer (beer_id),
   abv DECIMAL(2,1) not null,
   pint_price DECIMAL(1,2) not null,
   comment VARCHAR(255) null);

drop table if exists cask;
create table cask
  (cask_id INTEGER(6) AUTO_INCREMENT not null PRIMARY KEY,
   brewer INTEGER(6) not null,
     foreign key (brewer) references company (co_id),
   beer INTEGER(6) not null,
     foreign key (beer) references beer (beer_id),
   gyle INTEGER(6) not null,
     foreign key (gyle) references gyle (gyle_id),
   distributor INTEGER(6) not null,
     foreign key (distributor) references company (co_id),
   size INTEGER(2),
   cask_price DECIMAL(3,2) null,
   bar INTEGER(6) not null,
     foreign key (bar) references bar (bar_id),
   comment VARCHAR(255) null);

drop table if exists cask_meas;
create table cask_meas
  (meas_id INTEGER(6) AUTO_INCREMENT not null PRIMARY KEY,
   cask INTEGER(6) not null,
     foreign key (cask) references cask (cask_id),
   date VARCHAR(20) not null,
   volume VARCHAR(10) not null,
   comment VARCHAR(255) null);

drop table if exists company_address;
create table company_address
  (company INTEGER(6) not null,
     foreign key (company) references company(co_id),
   address INTEGER(6) not null,
     foreign key (address) references address(addr_id),
   primary key (company, address));

drop table if exists bar;
create table bar
  (bar_id INTEGER(3) AUTO_INCREMENT not null PRIMARY KEY,
   description TEXT null);

drop table if exists festival;
create table festival
  (fest_id INTEGER(4) AUTO_INCREMENT not null PRIMARY KEY,
   year INTEGER(4) not null,
   description VARCHAR(60) not null);