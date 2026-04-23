#!/bin/sh

if [ ! -f ".streamlit/secrets.toml" ]; then
    echo "Please start script in a directory containing .streamlit/secrets.toml"
    exit 1
fi

docker run -d --net=host --rm -v `pwd`/.streamlit:/app/.streamlit tfrayner/beerfestdb-dashboard:latest
