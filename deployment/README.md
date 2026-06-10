Deployment
==========

Configuration
-------------

Whether you are deploying using docker-compose or Kubernetes, you will need to edit 
some common configuration files first:

1. Edit the `../beerfestdb_web_site.yml` and
`../db/create_dbuser_account.sql` files to change the default database 
connection password. This step is optional, but __*highly recommended*__.

2. If you plan to use the tools dashboard, you will need to edit the Plugin::OpenIDConnect 
config, changing the URLs so that the dashboard and main app can communicate within the 
cluster. The URLs to change are `titus.local:3001` and `10.0.1.205:3001` which are the 
host, port and IP address of an example development server. Note that the IP address is 
used for the `url` setting in case your Kubernetes cluster or docker-compose setup is 
unable to resolve the server host name.

3. Also needed only for the tools dashboard, edit the config/dashboard-secrets.toml file 
(database password, URLs, and also make sure both the secret strings have been changed 
to something unique). The `client_secret` string must match the one in `beerfestdb_web_site.yaml`.

4. Edit the `environment.sh` file to allow settings to be injected into the deployment 
appropriately. See the notes in that file for more information.

Docker Compose
--------------

The simplest method to get BeerFestDB up and running is to use the
provided Docker container with docker-compose. For a quick start we 
recommend that you simply use the official images from Docker Hub:

-# FIXME try and remove this step if we can
1. Configure the settings in the following file. You will need to change the database password, and replace the `titus.local` string with the host address of your local deployment (`your-host` in the examples below):

   - docker-compose/docker-compose.yml

2. Generate a self-signed SSL certificate:

        sh ssl-certs-setup.sh

3. Run this command in the docker-compose directory to initialise the database and start the application:

        docker compose up

You should now be able to navigate to https://your-host:3001/app in your
web browser and log in (see below for default account details). You will 
need to accept the self-signed SSL certificate in your browser. Also 
check out the [tool dashboard module](tool_dashboard/README.md), which 
will be available at https://your-host:3001/dashboard

To run command-line scripts in the development environment, you can
use commands such as this (perhaps as part of an alias) to read and
write files within the project directory:

        docker-compose run -w /usr/src/BeerFestDB --rm app load_data.pl -i example_data/producers.csv

Files will be created as owned by the 'nobody' user; if desired, this can
be changed in the `docker-compose.yml` file.

If at any time you need to rebuild the app docker image, you can run something like 
these commands (changing the image tags as needed):

docker build -t tfrayner/catalyst-base:1.1 -f Dockerfile-catalyst .
docker build -t tfrayner/beerfestdb-base:1.2 -f Dockerfile-base .
docker build -t tfrayner/beerfestdb:1.2 .

Kubernetes
----------

The YAML files in the k8s directory provide the following:

1. `beerfestdb-volumes.yaml`: The manifest to create the namespace and volume mappings 
used for the database. Optional volume mappings for mounting the development codebase 
within your deployment are included as comments here. At a minimum you will need to edit
the database paths in this file:

- `/srv/beerfestdb/mysql` - the location of the actual mysql database directory to be created.
- `/home/tfrayner/src/beerfestdb/db` - the location of the `db` directory in a local copy of this git repo.

2. `beerfestdb-k8s.yaml`: The main deployment manifest. This includes the MySQL deployment,
the BeerFestDB webapp and nginx reverse proxy, the tool dashboard streamlit app, and the 
redis OpenID token store. If you want to mount a local copy of the codebase into the deployment 
for development purposes, you will need to uncomment the relevant sections in this file 
(and the corresponding sections in the `beerfestdb-volumes.yaml` file.). This is not necessary 
for production deployments.

3. The deployment of the app depends on a ConfigMap containing the environmental
variables. By default this is set up as an empty mapping. To point to a mounted project
directory (e.g. during development), uncomment the relevant sections of the webapp manifest YAML,
and recreate a populated ConfigMap by running this command in this directory once you have 
loaded the above YAML files:

``` bash
kubectl -n beerfestdb create secret generic beerfestdb-environment-secret --from-env-file=environment.sh
```

The main beerfestdb config file needs to be made available to the deployment as a Kubernetes 
Secret. For deployments we use the example YAML file which has already been set up with the 
appropriate configs. The tools dashboard app also needs a second Secret holding the database
credentials:

``` bash
kubectl -n beerfestdb create secret generic beerfestdb-web-yml --from-file beerfestdb_web.yml=beerfestdb_web_site.yml
# FIXME need to edit this post reorg:
kubectl -n beerfestdb create secret generic beerfestdb-dashboard-secret --from-file docker-compose/dashoard-config/secrets.toml
```

You will also need to set up SSL certificates in a second Kubernetes Secret. The simplest way to 
do this is to run the `docker-compose-ssl-certs-setup.sh` script in the `docker-compose` 
directory, and then run this command:

``` bash
kubectl -n beerfestdb create secret tls beerfestdb-tls-secret --cert=docker-compose/ssl/cert.pem --key=docker-compose/ssl/key.pem
```

FIXME also include OIDC key generation and secret

In addition to these YAML files, if you are running on a cluster using
traefik to manage ingresses, you will need to expose the webapp port
somehow. For traefik installed via Helm this can be a simple as adding
this HelmChartConfig object:

``` yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    ports:
      bfdbsecure:
        port: 3001
        expose:
          default: true
        exposedPort: 3001
      bfdbtoolsecure:
        port: 3002
        expose:
          default: true
        exposedPort: 3002
        tls:
          enabled: true
```

