Deployment
==========

Installation (Docker Compose)
-----------------------------

The simplest method to get BeerFestDB up and running is to use the
provided Docker container with docker-compose. There are just four
steps to get started, the first two of which can be skipped for an ultra-quick startup:

1. (OPTIONAL) Edit `docker-compose/beerfestdb_web_docker.yml` and
`../db/create_dbuser_account.sql` files to change the default database 
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
variables (principally in the `../.app_env` file) which are useful for development
but which should probably be deactivated in production. To change the
configuration in development, edit the `docker-compose/beerfestdb_web_docker.yml` file. For
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

