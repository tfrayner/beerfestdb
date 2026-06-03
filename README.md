BeerFestDB
==========

Welcome to BeerFestDB, a stock management database and website
designed, built and used by the volunteer cellar team at the Cambridge
Beer Festival.

This project has been developed to provide cellar teams with a full
stock control system, from initial beer ordering through delivery, to
recording dip figures and providing post-festival data analysis. A
flexible templating system is used to generate delivery checklists,
cask end signs, programme notes, and other important literature.

Any liquid refreshments can be managed using BeerFestDB (not just
beer!). Separate drinks departments can be given specific user
accounts with appropriate access controls.

Design Philosophy
-----------------

Since BeerFestDB has evolved as part of an ongoing series of festivals, 
it has been used at several different levels of complexity over the years.
Festivals can choose how much of the database functionality they need. 
Supported use-cases in order of increasing complexity:

- Basic festival product management: record which beers and breweries 
    were represented at each festival.
- Sales pricing, bar signage (cask-end signs, bar menus); allergen and
    vegan-suited product tracking.
- On-site cask management, including dips and sales reporting.
- Beer ordering and delivery tracking, automated order generation.

Our older, smaller festivals typically only recorded beers and prices; 
later, we started tracking daily sales via cask dips; finally we included 
beer ordering as part of the cellar process included in the database. 
We've retained support for all these ways of using the database, so that smaller 
festivals can start at a simpler level and then choose to use advanced
features as they grow larger.

Installation (using Docker)
---------------------------

The simplest method to get BeerFestDB up and running is to use the
provided Docker container with docker-compose. There are just four
steps to get started, the first two of which can be skipped for an ultra-quick startup:

1. (OPTIONAL) Edit `docker-compose/beerfestdb_web_docker.yml` and
`db/create_dbuser_account.sql` files to change the default database 
connection password. This step is optional, but __*highly recommended*__.

2. (OPTIONAL) Run these commands to rebuild the Docker image:

        docker build -t tfrayner/catalyst-base:1.1 -f Dockerfile-catalyst .
        docker build -t tfrayner/beerfestdb-base:1.2 -f Dockerfile-base .
        docker build -t tfrayner/beerfestdb:1.2 .

Alternatively, for a quick start we recommend that you simply use the official images
from Docker Hub, skipping directly to the next step.

3. Configure the host settings in the following files. You will need to replace the `titus.local` string with the host address of your local deployment (`your-host` in the examples below):

   - docker-compose/docker-compose.yml
   - docker-compose/beerfestdb_web_docker.yml
   - docker-compose/dashboard-config/secrets.toml

You will also need to generate a self-signed SSL certificate:

        cd docker-compose
        sh docker-compose-ssl-certs-setup.sh

4. Run this command in the docker-compose directory to initialise the database and start the application:

        docker compose up

You should now be able to navigate to https://your-host:8443/ in your
web browser and log in (see below for default account details). You will 
need to accept the self-signed SSL certificate in your browser. Also 
check out the [tool dashboard module](tool_dashboard/README.md), which 
will be available at https://your-host:8444/

The default docker-compose deployment sets some environmental
variables (principally in the `.app_env` file) which are useful for development
but which should probably be deactivated in production. To change the
configuration in development, edit the `beerfestdb_web_docker.yml` file. For
production, this file can either be baked into the Docker container or
included on a mounted volume. Within the docker container, the 
`$BEERFESTDB_WEB_CONFIG` environmental variable can be used to point 
to the desired config file.

To run command-line scripts in the development environment, you can
use commands such as this (perhaps as part of an alias) to read and
write files within the project directory:

        docker-compose run -w /usr/src/BeerFestDB --rm app load_data.pl -i example_data/producers.csv

Files will be created as owned by the 'nobody' user; if desired, this can
be changed in the `docker-compose.yml` file.

Installation (Kubernetes)
-------------------------

The `k8s` subdirectory contains manifest YAML files which have been 
successfully used to deploy `beerfestdb` + `nginx` + `mysql` on a 
`k3s+traefik` cluster. They are provided as an example of what is possible, 
but will likely require tailoring to your specific cluster environment.

Installation (without Docker/K8S)
---------------------------------

This approach is suited to a more old-school environment in which
Docker is not available and you simply want to install on a bare-metal
LAMP stack.

1. To start, you will need to install either MySQL or MariaDB. Create
a new database instance, and set up the database tables by loading in
`db/create_dbuser_account.sql`, `db/create_tables.sql` and
`db/initialise_vocabs.sql`, in that order. This sets up the following
default accounts:

| Username | Password |
| -------- | -------- |
| admin    | admin    |
| cellar   | cellar   |

2. Copy the `beerfestdb_web_site.yml` template to `beerfestdb_web.yml` 
and edit it to add the database connection details. If using a MySQL
database running on localhost with the default accounts set up in the
previous step, this is as simple as changing the following line:

        DBI:MariaDB:database=beerfestdb;host=mysql;port=3306

to this:

        DBI:MariaDB:database=beerfestdb;host=localhost;port=3306

3. Run `./script/beerfestdb_web_server.pl` to test the application. You
should now be able to connect to http://localhost:3000/ and look
around the website.

You can set up your production environment in a number of different
ways (see the Catalyst project at http://www.catalystframework.org/
for more information on this). A typical setup might use the Apache
webserver with FastCGI (via the `beerfestdb_web_fastcgi.pl`
script). Please consult the Apache documentation for help with this
configuration.

To set up the additional tools dashboard, please see the 
[dashboard README file](tool_dashboard/README.md) for instructions.

Mobile App
----------

The [BeerFestMobile](https://github.com/tfrayner/beerfest-mobile) app
will allow a cellar team to edit cask data (dips, vented/tapped/ready,
notes etc.) directly in the database as they work on their stillages.
This can save significant admin time between sessions.

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
