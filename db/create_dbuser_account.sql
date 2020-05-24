CREATE USER 'beerfestdb'@'localhost' IDENTIFIED BY 'vent&T4p';
GRANT ALL PRIVILEGES on beerfestdb.* TO 'beerfestdb'@'localhost' WITH GRANT OPTION;

CREATE USER 'beerfestdb'@'%' IDENTIFIED BY 'vent&T4p';
GRANT ALL PRIVILEGES on beerfestdb.* TO 'beerfestdb'@'%' WITH GRANT OPTION;
