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
