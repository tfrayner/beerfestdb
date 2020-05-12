FROM catalyst:1.0

WORKDIR /usr/src

COPY . .

RUN cpanm . && rm -rf ~/.cpanm

