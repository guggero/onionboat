FROM debian:buster-slim

ENV DOCKER_HOST unix:///tmp/docker.sock
ENV DOCKER_GEN_VERSION 0.7.7
ENV LC_ALL C.UTF-8
ENV DEBIAN_FRONTEND noninteractive

EXPOSE 9001

RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends gnupg2 \
                                                  apt-utils \
                                                  ca-certificates \
                                                  apt-transport-https \
                                                  diffutils \
                                                  patch  \
                                                  debconf-utils \
                                                  vim-tiny \
                                                  less \
                                                  procps \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ADD files/apt/tor.list /etc/apt/sources.list.d/tor.list
RUN gpg --keyserver keyserver.ubuntu.com --recv-key 74A941BA219EC810 \
    && gpg --export 74A941BA219EC810 | apt-key add -

RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends ca-certificates \
                                                  wget \
                                                  supervisor \
                                                  deb.torproject.org-keyring \
                                                  tor \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup supervisord
ADD files/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# Install docker-gen
RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

ADD files/docker-gen/torrc.tmpl /app/torrc.tmpl

VOLUME ["/var/lib/tor/hidden_services"]

WORKDIR /app

## Add startup script.
ADD bin/run.sh /app/bin/run.sh
RUN chmod 0755 /app/bin/run.sh

ENTRYPOINT ["/app/bin/run.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
