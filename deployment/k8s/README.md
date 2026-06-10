Kubernetes deployment
---------------------

The YAML files in this directory provide the following:

1. `beerfestdb-mysql-deploy.yaml`: The manifest to get the mysql
database up and running using the table creation statements and
controlled vocabulary terms in the `db` directory.

2. `beerfestdb-k8s.yaml`: The main beerfestdb+nginx webapp manifest.

Both these YAML files should be reviewed; you will almost certainly
want to change the file paths mounted into the images:

- `/srv/beerfestdb/mysql` - the location of the actual mysql database directory to be created.
- `/home/tfrayner/src/beerfestdb/db` - the location of the `db` directory in a local copy of this git repo.

IMPORTANT: the deployment of the app depends on a ConfigMap containing the environmental
variables. By default this is set up as an empty mapping. To point to a mounted project
directory (e.g. during development), uncomment the relevant sections of the webapp manifest YAML,
and recreate a populated ConfigMap by running this command in this directory once you have 
loaded the above YAML files:

``` bash
kubectl -n beerfestdb create configmap beerfestdb-app-config --from-env-file=../.app_env
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

