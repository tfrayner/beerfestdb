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
        tls:
          enabled: true
```
