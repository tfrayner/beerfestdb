-- Note that your deployment probably only needs to run one or the other of these, not both.  
-- The first creates a user that can only connect from localhost, the second allows 
-- connections from any host.  Adjust as necessary for your environment.

CREATE USER 'beerfestdb'@'localhost' IDENTIFIED BY 'vent&T4p';
GRANT SELECT, INSERT, UPDATE, DELETE, SHOW VIEW ON beerfestdb.* TO 'beerfestdb'@'localhost';

CREATE USER 'beerfestdb'@'%' IDENTIFIED BY 'vent&T4p';
GRANT SELECT, INSERT, UPDATE, DELETE, SHOW VIEW ON beerfestdb.* TO 'beerfestdb'@'%';
