FROM debian:wheezy
MAINTAINER Quentin Van Itterbeeck <qvi@taktik.be>
ENV DEBIAN_FRONTEND noninteractive

# Configure backports
RUN echo "deb http://http.debian.net/debian wheezy-backports main" >> /etc/apt/sources.list
RUN apt-get -qq update

# Install prereqs
RUN apt-get --no-install-recommends -y install \
    build-essential \
    ca-certificates \
    curl \
    erlang-dev \
    erlang-nox \
    git \
    libicu-dev \
    libmozjs185-dev \
    python
RUN apt-get -y install curl wget nodejs erlang-reltool
RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN apt-get -y install nodejs
RUN npm install -g grunt-cli
RUN apt-get install -y openssh-server vim
RUN mkdir /var/run/sshd
RUN echo 'root:T@kt1k' | chpasswd
RUN sed -i "s/PermitRootLogin without-password/PermitRootLogin yes/" /etc/ssh/sshd_config

# Build couchdb
RUN useradd -m couchdb
RUN mkdir -p /home/couchdb
ADD . /home/couchdb
USER root
RUN chown -R couchdb:couchdb /home/couchdb
USER couchdb
WORKDIR /home/couchdb

# We don't to be so strict for simple testing.
#RUN sed -i'' '/require_otp_vsn/d' rebar.config.script

# Expose nodes on external network interface
RUN sed -i'' 's/bind_address = 127.0.0.1/bind_address = 0.0.0.0/' rel/overlay/etc/default.ini

# Build
RUN ./configure --prefix=/opt/couchdb --disable-docs
RUN make
USER root
RUN make install
RUN cp -r /home/couchdb/share/www /opt/couchdb/share/

EXPOSE 5984 5986 4369 44001 2222
ENTRYPOINT ["/home/couchdb/bin/run.sh"]
