BeerFestDB
==========

Welcome to BeerFestDB, a stock management database and website
designed, built and used by the volunteer cellar team at the Cambridge
Beer Festival.

This project has been developed to provide your cellar team a full
stock control system, from initial beer ordering through delivery, to
recording dip figures and providing post-festival data analysis. A
flexible templating system is used to generate delivery checklists,
cask end signs, programme notes, and other important literature.

Any liquid refreshments can be managed using BeerFestDB (not just
beer!). Separate drinks departments can be given specific user
accounts with appropriate access controls.


Installation (using Docker)
---------------------------

The simplest method to get BeerFestDB up and running is to use the
provided Docker container with docker-compose. There are just three
steps to get started:

1. Edit beerfestdb_web.yml and db/create_dbuser_account.sql to change
the default database connection password. This step is optional, but
highly recommended.

2. Run these commands to build the Docker container:

        docker build -t catalyst:1.0 -f Dockerfile-catalyst .
        docker build -t beerfestdb:1.0 .

3. Run this command to initialise the database and start the application:

        docker-compose up

You should now be able to navigate to http://localhost:8080/ in your
web browser and log in (see below for default account details).

The default docker-compose deployment sets some environmental
variables, principally in .app_env, which are useful for development
but which should probably be deactivated in production. To change the
default configuration in development, you can replace the
beerfestdb_web_site.yml symbolic link with a file containing your desired
changes. For production, the configuration can be baked in to the
Docker container by changing the beerfestdb_web.yml file itself.

To run command-line scripts in the development environment, you can
use commands such as this (perhaps as part of an alias) to read and
write files within the project directory:

        docker-compose run -w /usr/src/BeerFestDB --rm app load_data.pl -i example_data/producers.csv

Files will be created as owned by the 'nobody' user; if desired, this can
be changed in the docker-compose.yml file.


Installation (without Docker)
-----------------------------

This approach is suited to a more old-school environment in which
Docker is not available and you simply want to install on a bare-metal
LAMP stack.

1. To start, you will need to install either MySQL or MariaDB. Create
a new database instance, and set up the database tables by loading in
db/create_dbuser_account.sql, db/create_tables.sql and
db/initialise_vocabs.sql, in that order. This sets up the following
default accounts:

| Username | Password |
| -------- | -------- |
| admin    | admin    |
| cellar   | cellar   |

2. Edit beerfestdb_web.yml to add the database connection details. If
using a MySQL database running on localhost with the default accounts
set up in the previous step, this is as simple as changing the
following line:

        DBI:mysql:beerfestdb:mysql:3306

to this:

        DBI:mysql:beerfestdb:localhost:3306

3. Run script/beerfestdb_web_server.pl to test the application. You
should now be able to connect to http://localhost:3000/ and look
around the website.

You can set up your production environment in a number of different
ways (see the Catalyst project at http://www.catalystframework.org/
for more information on this). A typical setup might use the Apache
webserver with FastCGI (via the beerfestdb_web_fastcgi.pl
script). Please consult the Apache documentation for help with this
configuration.


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
