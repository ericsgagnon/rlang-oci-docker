# docker build -t ericsgagnon/rstudio:4.0.3 .
# docker build -t ericsgagnon/rstudio:4.0.3 -f dev.dockerfile .
# Extends rocker/ml-verse with :
# - mariadb
# - oracle instantclient
# - freetds
# - additional R packages
# - go
# - python (update sym link to 3.7 from rocker/geospatial image)

ARG R_MAJOR=4
ARG R_MINOR=0
ARG R_PATCH=3
ARG R_MAJOR_MINOR_V=$R_MAJOR.$R_MINOR
ARG R_V=$R_MAJOR.$R_MINOR.$R_PATCH
ARG GOLANG_V=1.15
ARG RUST_V=1.48
ARG PYTHON_V=3.9
ARG CODE_SERVER_V=3.7.4
ARG ACCEPT_MS_EULA=Y
ARG ARGO_V=v2.12.0-rc4

FROM rocker/ml-verse:${R_V}     as rlang
FROM golang:${GOLANG_V}         as golang
FROM rust:${RUST_V}             as rustlang
FROM python:${PYTHON_V}         as python
FROM argoproj/argocli:${ARGO_V} as argocli

# base ############################################################################################
FROM rlang

# args and environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LANG=en_US.UTF-8
ENV PASSWORD password
ENV SHELL=/bin/bash
ENV WORKSPACE=/workspace

# this may not be necessary but may give insight on source files
COPY . ${WORKSPACE}/

RUN chsh -s /bin/bash

# install os libraries, utilities, etc.
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    ca-certificates \
    libnss-wrapper \
    libuid-wrapper \
    libpam-wrapper \
    gettext \
    libbluetooth-dev \
    tk-dev \
    uuid-dev \
    lsb-release \
    g++ \
    gcc \
    libc6-dev \
    make \
    pkg-config \
    gnupg \
    gnupg2 \
    apt-transport-https \
    curl \
    net-tools \
    nano \
    apt-utils \
    aptitude \
    man \
    software-properties-common \
    dumb-init \
    htop \
    locales \
    procps \
    ssh \
    sudo \
    vim \
    libpam-mount \
    cifs-utils \
    nfs-common \
    sshfs \
    encfs \
    ecryptfs-utils \
    python3-keyring \
    libsecret-tools \
    lastpass-cli \
    xclip \
    fuse3 \
    libfuse3-dev \
    gprename \
    pax \
    rsync \
    iputils-ping \
    netcat \
    dnsutils \
    nmap \
    traceroute \
    vnstat \
    iptraf \
    iftop \
    slurm \
    tcpdump \
    moreutils \
    && rm -rf /var/lib/apt/lists/*

# nss wrapper lets us mount passwd and group files if necessary
ENV LD_PRELOAD=libnss_wrapper.so \
    NSS_WRAPPER_PASSWD=/etc/passwd \
    NSS_WRAPPER_GROUP=/etc/group

# user home directories ####################################################

RUN mkdir -p \
    /etc/skel/.local/bin   \
    /etc/skel/.local/share \
    /etc/skel/.config      \
    /etc/skel/.cache       \
    && echo 'export PATH=$PATH'           >> /etc/skel/.bashrc \
    && cat $WORKSPACE/bashrc.env.sh | envsubst >> /etc/skel/.bashrc

COPY skel-rsync.sh /etc/profile.d/
# Databases ################################################################

# Install os drivers for common db's 
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    unixodbc \
    unixodbc-dev \
    libaio1 \
    tdsodbc \
    odbc-postgresql \
    libsqliteodbc \
    mariadb-client

COPY ./odbcinst.ini /opt/odbcinst.ini

# microsoft ###################################################################################
# ms still demands accepting their license agreement...
ENV ACCEPT_EULA Y
ENV PATH=$PATH:/opt/mssql-tools/bin

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/msprod.list

RUN apt-get update && apt-get install -y mssql-tools

# oracle ######################################################################################
ENV OCI_LIB=/opt/oracle/instantclient

COPY ./oci8.pc /usr/lib/pkgconfig/oci8.pc

RUN mkdir /opt/oracle && cd /opt/oracle \  
    && for file in basic odbc sqlplus tools sdk jdbc ; do \
        wget -O "instantclient-${file}" "https://download.oracle.com/otn_software/linux/instantclient/instantclient-${file}-linuxx64.zip" ; \
        unzip instantclient-${file} ; \
        rm -f instantclient-${file} ; \
        done \
    && mv /opt/oracle/instantclient_* /opt/oracle/instantclient \
    && sh -c "echo /opt/oracle/instantclient > /etc/ld.so.conf.d/oracle-instantclient.conf" \
    && ldconfig

# freetds #####################################################################################
RUN mkdir /opt/freetds && cd /opt/freetds \
    && wget -O freetds.tar.gz ftp://ftp.freetds.org/pub/freetds/stable/freetds-1.2.12.tar.gz \  
    && tar xvf freetds.tar.gz \
    && rm freetds.tar.gz \
    && ln -s freetds-1.2.12 freetds \
    && cd freetds \
    && ./configure \
    && make \
    && make install \
    && cat /opt/odbcinst.ini >> /etc/odbcinst.ini \
    && rm /opt/odbcinst.ini
# R ###########################################################################################
ARG R_V
ENV R_VERSION=$R_V
ARG R_MAJOR_MINOR_V
ENV R_MAJOR_MINOR=$R_MAJOR_MINOR_V
ENV R_ENVIRON_USER=~/.config/R/.Renviron
ENV R_PROFILE_USER=~/.config/R/.Rprofile

COPY .Rprofile /etc/skel/.config/R/
#COPY .Renviron /etc/skel/.config/R/
COPY .Renviron /etc/R/
#COPY .Rprofile /etc/R/

RUN mkdir -p /etc/skel/.local/share/R/$R_MAJOR_MINOR/lib  \
    && echo "R_LIBS_USER=${R_LIBS_USER-'~/.local/share/R/"$R_MAJOR_MINOR"/lib'}"    >> /usr/local/lib/R/etc/Renviron \
    && echo "R_MAJOR_MINOR=$R_MAJOR_MINOR"                                          >> /usr/local/lib/R/etc/Renviron \
    && echo "R_VERSION=$R_VERSION"                                                  >> /usr/local/lib/R/etc/Renviron \
    && echo "R_ENVIRON_USER=$R_ENVIRON_USER"                                        >> /usr/local/lib/R/etc/Renviron \
    && echo "R_PROFILE_USER=$R_PROFILE_USER"                                        >> /usr/local/lib/R/etc/Renviron

# commenting during dev to improve build time
# RUN xargs -I {} -a /tmp/packages -0 install2.r -s --deps TRUE -n 8 {} # not this one - behavior changed when moving to ubuntu
# RUN head /tmp/packages | tr '\n' ' ' | install2.r -s --deps TRUE -n 8 

# python ##################################################
ARG PYTHON_V
ENV PYTHON_VERSION=$PYTHON_V

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH
# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

COPY --from=python /usr/local/lib/  /usr/local/lib/
COPY --from=python /usr/local/bin/  /usr/local/bin/

# go ######################################################
ARG GOLANG_V
ENV GOLANG_VERSION=$GOLANG_V
ENV GOPATH '$HOME/.local/share/go'
ENV GOBIN  '$HOME/.local/bin'
ENV PATH $GOBIN:/usr/local/go/bin:$PATH

COPY --from=golang  /usr/local/go /usr/local/go
RUN  mkdir -p \
    /etc/skel/.local/share/go \
    /etc/skel/.local/bin/go \
    && echo 'export GOPATH=$HOME/.local/share/go' >> /etc/skel/.bashrc \
    && echo 'export GOBIN=$HOME/.local/bin/go'    >> /etc/skel/.bashrc

# rust ####################################################
ARG RUST_V
ENV RUST_VERSION=$RUST_V

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

COPY --from=rustlang  /usr/local/rustup /usr/local/rustup
COPY --from=rustlang  /usr/local/cargo /usr/local/cargo

# kubectl #################################################
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && apt-get install -y \
    kubeadm \
    kubectl \
    && echo 'source <(kubectl completion bash)' > /etc/profile.d/kubectl-completion.sh

# helm ####################################################
RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash \
    && echo 'source <(helm completion bash)' > /etc/profile.d/helm-autocompletion.sh

# docker cli ##############################################
RUN curl -fsSL https://get.docker.com | bash
    # && addgroup --gid 1250 docker

# argo workflow cli #######################################
ARG ARGO_V
ENV ARGO_VERSION=${ARGO_V}
ENV PATH=/usr/local/argo/bin:$PATH
COPY --from=argocli /bin/argo /usr/local/argo/bin/argo

# code server #############################################
#ARG CODE_SERVER_V
#ENV CODE_SERVER_VERSION=$CODE_SERVER_V

#RUN chsh -s /bin/bash
#ENV SHELL=/bin/bash

# RUN adduser --gecos '' --disabled-password coder \
#     && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

# RUN ARCH="$(dpkg --print-architecture)" && \
#     curl -fsSL "https://github.com/boxboat/fixuid/releases/download/v0.4.1/fixuid-0.4.1-linux-$ARCH.tar.gz" | tar -C /usr/local/bin -xzf - && \
#     chown root:root /usr/local/bin/fixuid && \
#     chmod 4755 /usr/local/bin/fixuid && \
#     mkdir -p /etc/fixuid && \
#     printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml


# git clone --depth 1 --branch v$CODE_SERVER_VERSION https://github.com/cdr/code-server.git
# COPY release-packages/code-server*.deb /tmp/
# COPY ci/release-image/entrypoint.sh /usr/bin/entrypoint.sh
# RUN dpkg -i /tmp/code-server*$(dpkg --print-architecture).deb && rm /tmp/code-server*.deb

# EXPOSE 8080
# # This way, if someone sets $DOCKER_USER, docker-exec will still work as
# # the uid will remain the same. note: only relevant if -u isn't passed to
# # docker-run.
# USER 1000
# ENV USER=coder
# WORKDIR /home/coder
# ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]

# R apparently hates the idea of inheriting env vars from the host, using a hack to deal with this
#RUN cat $WORKSPACE/.Renviron | envsubst > /etc/skel/.config/R/.Renviron
RUN cat $WORKSPACE/.Renviron | envsubst > /etc/skel/.config/R/.Renviron


# docker build -t ericsgagnon/rstudio:4.0.3 -f Dockerfile .
# docker run -dit --name devdev -p 8787:8787 -e PASSWORD=password ericsgagnon/rstudio:4.0.3
