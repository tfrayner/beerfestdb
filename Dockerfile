FROM catalyst:1.0

# Install BeerFestDB.
WORKDIR /usr/src
COPY . .
RUN   cpanm . \
   && rm -rf ~/.cpanm \
   && mkdir /etc/beerfestdb \
   && cp beerfestdb_web.yml /etc/beerfestdb/

# Clean up src directory.
WORKDIR /usr
RUN   rm -rf src

ENV BEERFESTDB_WEB_CONFIG=/etc/beerfestdb/beerfestdb_web.yml

CMD beerfestdb_web_server.pl -r
