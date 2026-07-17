Deployment
==========

The following instructions describe how to set up a containerised deployment serving the main 
webapp and tools dashboard from an example server at https://titus.local:3001/

Configuration
-------------

Whether you are deploying using docker-compose or Kubernetes, you will first need to edit 
some common configuration files and generate some SSL certificates:

1. Edit the `../beerfestdb_web_site.yml` and `../db/create_dbuser_account.sql`
files to change the default database connection password. This step is 
optional, but __*highly recommended*__. Note that there are currently four separate 
locations in which the password should be set:

- `../beerfestdb_web_site.yml`
- `../db/create_dbuser_account.sql`  # in two places
- `./docker-compose/docker-compose.yml`
- `./config/dashboard-secrets.toml`

2. If you plan to use the tools dashboard, you will need to edit the Plugin::OpenIDConnect 
config, changing the URLs so that the dashboard and main app can communicate within the 
cluster. The URLs to change are `titus.local:3001` and `10.0.1.205:3001` which are the 
host, port and IP address of an example development server. Note that the IP address is 
used for the `url` setting in case your Kubernetes cluster or docker-compose setup is 
unable to resolve the server host name.

3. Also needed only for the tools dashboard, edit the config/dashboard-secrets.toml file 
(database password, URLs, and also make sure both the secret strings have been changed 
to something unique). The `client_secret` string must match the one in `beerfestdb_web_site.yaml`.

4. Edit the `config/environment.sh` file to allow settings to be injected into the deployment 
appropriately. See the notes in that file for more information.

5. Generate a self-signed SSL certificate. You should edit the `ssl-certs-setup.sh` script
to replace the `titus.local` and `10.0.1.205` addresses with your own server hostname and
IP address (the IP address is not needed if your cluster DNS can resolve the server hostname).
Then just run it to create the `ssl/` directory containing the certificate and key:

``` bash
sh ssl-certs-setup.sh
```

6. Generate keys for the OpenID Connect component (required for tool dashboard login):

``` bash
# Keys will be created under ../keys
sh ../generate_oidc_keys.sh
```

Docker Compose
--------------

Please complete the **Configuration** section before the following steps.

The simplest method to get BeerFestDB up and running is to use the
provided Docker container with docker-compose. For a quick start we 
recommend that you simply use the official images from Docker Hub:

1. Configure the settings in the following file. You will need to change the database 
password, and replace the `titus.local` string with the host address of your local 
deployment (`your-host` in the examples below):

   - docker-compose/docker-compose.yml

2. Ensure that the OIDC keys are securely readable within the docker deployment:

``` bash
# Change ownership to the `nobody` user, UID=65534
sudo chown 65534 ../../keys/*.pem
```

3. Run this command in the `docker-compose/` directory to initialise the database and start the application:

``` bash
docker compose up
```

You should now be able to navigate to https://your-host:3001/app in your
web browser and log in (see below for default account details). You will 
need to accept the self-signed SSL certificate in your browser. Also 
check out the [tool dashboard module](tool_dashboard/README.md), which 
will be available at https://your-host:3001/dashboard

To run command-line scripts in a mounted **development** environment, you can
use commands such as this (perhaps as part of an alias) to read and
write files within the project directory:

``` bash
docker-compose run -w /usr/src/BeerFestDB --rm app load_data.pl -i example_data/producers.csv
```

Files will be created as owned by the 'nobody' user; if desired, this can
be changed in the `docker-compose.yml` file.

Kubernetes
----------

Please complete the **Configuration** section before the following steps. Run the following
steps in the `deployment` directory:

1. `beerfestdb-volumes.yaml`: The manifest to create the namespace and volume mappings 
used for the database. Optional volume mappings for mounting the development codebase 
within your deployment are included as comments here. At a minimum you will need to edit
the database paths in this file:

- `/srv/beerfestdb/mysql` - the location of the actual mysql database directory to be created.
- `/home/tfrayner/src/beerfestdb/db` - the location of the `db/` directory in a local copy of this git repo.

Deploy these changes to your cluster:

``` bash
kubectl apply -f k8s/beerfestdb-volumes.yaml
```

It is wise to quickly check that the volumes have been correctly set up at this point. The following command should show two `beerfestdb-*` volumes with STATUS=Bound:

``` bash
kubectl get pv
```

2. Additional configuration: the deployment of the app depends on a set of Kubernetes Secrets
containing environmental variables, config files and SSL certificates:

``` bash
kubectl -n beerfestdb create secret generic beerfestdb-environment-secret\
            --from-env-file=config/environment.sh
```

The main beerfestdb config file needs to be made available to the deployment as a Kubernetes 
Secret. For deployments we use the example YAML file which has already been set up with the 
appropriate settings. The tools dashboard app also needs a second Secret holding the database
credentials:

``` bash
kubectl -n beerfestdb create secret generic beerfestdb-web-yml \
            --from-file beerfestdb_web.yml=../beerfestdb_web_site.yml
kubectl -n beerfestdb create secret generic beerfestdb-dashboard-secret \
            --from-file secrets.toml=config/dashboard-secrets.toml
```

You will also need to set up the SSL certificates generated earlier in a second Kubernetes Secret:

``` bash
kubectl -n beerfestdb create secret tls beerfestdb-tls-secret \
           --cert=ssl/cert.pem --key=ssl/key.pem
```

For tools dashboard use, we need to add an additional set of keys for OpenID Connect:

``` bash
kubectl -n beerfestdb create secret generic beerfestdb-oidc-secret \
           --from-file=../keys/public.pem \
           --from-file=../keys/private.pem
```

3. `beerfestdb-k8s.yaml`: The main deployment manifest. This includes the MySQL deployment,
the BeerFestDB webapp and nginx reverse proxy, the tool dashboard streamlit app, and the 
redis OpenID token store. If you want to mount a local copy of the codebase into the deployment 
for development purposes, you will need to uncomment the relevant sections in this file 
(and the corresponding sections in the `beerfestdb-volumes.yaml` file.). This is not necessary 
for production deployments.

Deploy the application to your cluster:

``` bash
kubectl apply -f k8s/beerfestdb-deploy.yaml
```

4. In addition to these YAML files, you will need to set up an ingress of some kind so that you 
can access the webapp from outside the cluster. If you are running on a cluster using Helm-installed
Traefik to manage ingresses, this can be a simple as adding this HelmChartConfig object to your cluster:

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
```

Note that this entry point should not be TLS-enabled, since TLS is instead handled by the nginx deployment.

Building Docker Images
----------------------

If at any time you need to rebuild the app docker image, you can run something like 
these commands (changing the image tags as needed):

``` bash
docker build -t tfrayner/catalyst-base:1.1 -f Dockerfile-catalyst .
docker build -t tfrayner/beerfestdb-base:1.2 -f Dockerfile-base .
docker build -t tfrayner/beerfestdb:1.2 .
```

