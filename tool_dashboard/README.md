= Cambridge Beer Festival =
== BeerfestDB Tool Dashboard ==

A collection of handy little utilities for using data in beerfestdb

Requirements for python scripts are in requirements.txt. Put this file in /path/to/venv/ if using a virtual environment (recommended; see https://docs.python.org/3/library/venv.html)

Also create a /path/to/.streamlit/ directory. This will hold the secrets.toml file (DO NOT commit a secrets file to github or any other version control).

== Setup ==

Create and activate a python virtual environment. Run the following to install dependencies:

``` bash
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```

Create a `.streamlit` subdirectory containing a file `secrets.toml` which looks something like this:

```
[connections.cbf]
# Connection to the BeerFestDB MySQL/MariaDB database (read-only access only)
dialect = "mysql"
host = "127.0.0.1"
port = 3306
database = "beerfestdb"
username = "myusername"
password = "mypassword"

[auth]
# Both secrets should be long, hard-to-guess strings. You will need to register the
# redirect_uri, client_id and client_secret with the OpenID provider
redirect_uri = "http://localhost:8501/oauth2callback"
cookie_secret = "xxx"

client_id = "dashboard"
client_secret = "xxx"
server_metadata_url = "http://localhost/.well-known/openid-configuration"

[app]
# Inactivity timeout in minutes before the user is automatically logged out.
inactivity_timeout_minutes = 60
```

Run the streamlit app:

``` bash
streamlit run CBF_tool_page.py
```

You should now be able to point your browser at the app using the URL(s) that streamlit gives you.

== Docker ==

To create a docker image, run:

``` bash
docker build . -t tfrayner/beerfestdb-dashboard:latest
```

To run it on the same host as the MySQL database and web UI, create `.streamlit/secrets.toml` in the current directory, configure the `[auth]` section appropriately, and run:

``` bash
# Forward the local config into the docker container using -v argument
docker run -d --net=host --rm -v `pwd`/.streamlit:/app/.streamlit tfrayner/beerfestdb-dashboard:latest
```

Alternatively, you can simply run the `run_docker_image.sh` script in this directory, which will alert you if the secrets.toml file cannot be found.

Once running, the web dashboard will be accessible on the host at port 8501.
