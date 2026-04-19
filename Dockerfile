FROM tfrayner/beerfestdb-base:1.1

# Install BeerFestDB.
WORKDIR /usr/src
COPY . .
RUN   cpanm TODDR/Crypt-OpenSSL-RSA-0.35.tar.gz \
   && cpanm ExtUtils::MakeMaker::CPANfile \
   && git clone https://github.com/tfrayner/catalyst-plugin-openidconnect.git \
   && cd catalyst-plugin-openidconnect && cpanm . && cd .. \
   && cpanm . \
   && rm -rf ~/.cpanm \
   && mkdir /etc/beerfestdb \
   && cp beerfestdb_web.yml /etc/beerfestdb/ \
   && cd /usr && rm -rf /usr/src

WORKDIR /var/tmp

ENV BEERFESTDB_WEB_CONFIG=/etc/beerfestdb/beerfestdb_web.yml

CMD ["beerfestdb_web_server.pl", "-r"]
