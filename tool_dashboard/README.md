= Cambridge Beer Festival =
== BeerfestDB Tool Dashboard ==

A collection of handy little utilities for using data in beerfestdb

Requirements for python scripts are in requirements.txt. Put this file in /path/to/venv/ if using a virtual environment (recommended; see https://docs.python.org/3/library/venv.html)

Also create a /path/to/.streamlit/ directory. This will hold the secrets.toml file (DO NOT commit a secrets file to github or any other version control).

== Setup ==

Create and activate a python virtual environment. Run the following to install dependencies:

``` bash
pip install -r requirements.txt
```

Create a `.streamlit` subdirectory containing a file `secrets.toml` which looks something like this:

```
[connections.cbf]
dialect = "mysql"
host = "127.0.0.1"
port = 3306
database = "beerfestdb"
username = "myusername"
password = "mypassword"
```

Run the streamlit app:

``` bash
streamlit run CBF_tool_page.py
```

You should now be able to point your browser at the app using the URL(s) that streamlit gives you.
