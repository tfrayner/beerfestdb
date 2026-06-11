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

Features
--------

- Highly configurable, product-agnostic stock control website with relational database backend
- Comprehensive process documentation tested across multiple live festivals
- Tools dashboard writen using `streamlit` for rapid development of new data visualisations
- JSON-based API allowing programmatic access
- R package facilitating festival data download via API
- [Mobile app](https://github.com/tfrayner/beerfestdb-mobile) for live recording of common cellaring tasks
- Support for deployment via containerisation

Deployment using Docker Images
------------------------------

This is the simplest way to get the system up and running. See the
[deployment README](deployment/README.md) for details on how to run 
BeerFestDB from a set of docker images using either Docker Compose or
Kubernetes.

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

