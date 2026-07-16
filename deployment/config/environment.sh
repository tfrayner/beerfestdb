## Default deployment should use a random password for the MySQL root user
MYSQL_RANDOM_ROOT_PASSWORD=1

## Alternatively, uncomment this line and set a specific password for the MySQL root user.
## This is not recommended for production environments, but will be useful for testing or development purposes.
#MYSQL_ROOT_PASSWORD=secret

## The following lines support a development deployment mounting the
## project directory at /usr/src/BeerFestDB. They should be commented out for
## production docker deployments:
#PERL5LIB=/usr/src/BeerFestDB/lib
#BEERFESTDB_WEB_CONFIG=/usr/src/BeerFestDB/beerfestdb_web.yml
#BEERFESTDB_ROOT_PATH=/usr/src/BeerFestDB/root

# Tell Streamlit the external address so OIDC static asset URLs are correct.
# Without these, Streamlit defaults to 'localhost' in generated URLs.
STREAMLIT_BROWSER_SERVER_ADDRESS=titus.local

# This port will have been defined by the ingress entrypoint (e.g. in Traefik)
STREAMLIT_BROWSER_SERVER_PORT=3001

## Do not change this
MYSQL_DATABASE=beerfestdb
