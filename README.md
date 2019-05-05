BeerFestDB
==========

Welcome to BeerFestDB, a stock management database and website
designed and built (and used!) by actual volunteers at the Cambridge
Beer Festival.

This project has been developed to provide your cellar team a full
stock control system, from initial beer ordering through delivery, to
recording dip figures and providing post-festival data analysis. A
flexible templating system is used to generate delivery checklists,
cask end signs, programme notes, and other important literature.

Not only beer, but any liquid refreshments can be managed using
BeerFestDB. Separate drinks departments can be given specific user
accounts with appropriate access controls.


Installation
------------

To start, you will need to install either MySQL or MariaDB. Create a
new database instance, and set up the database tables by loading in
db/create_tables.sql and db/initialise_vocabs.sql, in that order. This
sets up the following default accounts:

| Username | Password |
| -------- | -------- |
| admin    | admin    |
| cellar   | cellar   |

Make a copy of beerfestdb_web.yml-example as beerfestdb_web.yml and
edit it to add the database connection details.

Run script/beerfestdb_web_server.pl to test the application. You
should now be able to connect to http://localhost:3000/ and look
around the website. You can set up your production environment in a
number of different ways (see the Catalyst project for more
information on this. A typical setup might use Apache with FastCGI
(via the beerfestdb_web_fastcgi.pl script). Please consult the Apache
documentation for help with this configuration.


Credits
-------

Thanks to Mark James for allowing the use of his excellent Silk icon
set:

  http://www.famfamfam.com/lab/icons/silk/

Thanks also to the TargetProcess team for contributing their ExtJS 3.0
theme:

  http://www.targetprocess.com/Files/TargetProcessSkin_ext_3.zip

Finally, a sincere thank you to Roger Stark, who helped design the
original BeerFestDB database schema many years ago.
