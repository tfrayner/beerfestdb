CREATE USER 'beerfestdb'@'localhost' IDENTIFIED BY 'vent&T4p';
GRANT SELECT, INSERT, UPDATE, DELETE ON beerfestdb.* TO 'beerfestdb'@'localhost';

CREATE USER 'beerfestdb'@'%' IDENTIFIED BY 'vent&T4p';
GRANT SELECT, INSERT, UPDATE, DELETE ON beerfestdb.* TO 'beerfestdb'@'%';

-- FIXME A REMINDER TO IMPLEMENT THIS IN PRODUCTION