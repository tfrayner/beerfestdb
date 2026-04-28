FROM tfrayner/beerfestdb-base:1.1

# Install BeerFestDB.
WORKDIR /usr/src
COPY . .
RUN   cpanm . \
   && rm -rf ~/.cpanm \
   && mkdir /etc/beerfestdb \
   && cp beerfestdb_web_site.yml /etc/beerfestdb/beerfestdb_web.yml \
   && mkdir -p /path/to/beerfestdb/keys/ \
   && cp t/keys/*.pem /path/to/beerfestdb/keys/ \
   && cd /usr && rm -rf /usr/src

WORKDIR /var/tmp

ENV BEERFESTDB_WEB_CONFIG=/etc/beerfestdb/beerfestdb_web.yml

CMD ["beerfestdb_web_server.pl", "-r"]
