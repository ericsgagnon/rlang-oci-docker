# docker build -t ericsgagnon/rstudio:v4.0.3 .
# Extends rocker/geospatial with :
# - mariadb
# - oracle instantclient
# - freetds
# - additional R packages
# - go
# - python (update sym link to 3.7 from rocker/geospatial image)

ARG   OIC_VERSION=19.6
ARG   R_VERSION=4.0.3
ARG   GO_VERSION=1.15

# Rlang ############################################################################################
FROM rocker/geospatial:${R_VERSION} as rlang

ARG  OIC_VERSION
ARG  R_VERSION

ENV  OIC_VERSION=${OIC_VERSION}
ENV  R_VERSION=${R_VERSION}

ENV  LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH
ENV  OCI_LIB=/opt/oracle/instantclient
ENV  OCI_INC=/opt/oracle/instantclient/sdk/include
ENV  PATH=$PATH:/opt/oracle/instantclient

# install system libraries and tools to 
RUN 

# MS SQL Server! maybe we can drop freetds...
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/msprod.list \

#mssql-tools unixodbc-dev
#echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile

# ms still demands accepting their license agreement...
ENV ACCEPT_EULA Y

RUN apt-get update && apt-get install -y \
		libbluetooth-dev \
		tk-dev \
		uuid-dev \
    lsb-release \
	  && rm -rf /var/lib/apt/lists/*













# Install os drivers for common db's 
RUN apt update && apt install -y --no-install-recommends \
  g++ \
  gcc \
  libc6-dev \
  pkg-config \
  gnupg \
  apt-transport-https \
  unixodbc \
  unixodbc-dev \
  libaio1 \
  tdsodbc \
  odbc-postgresql \
  libsqliteodbc \
  mariadb-client \
  curl \
  net-tools \
  nano

COPY ./oci8.pc /usr/lib/pkgconfig/oci8.pc
COPY ./odbcinst.ini /opt/odbcinst.ini



RUN mkdir /opt/oracle && cd /opt/oracle \
  && wget -O instantclient-basic   "https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linuxx64.zip" \
  && wget -O instantclient-odbc    "https://download.oracle.com/otn_software/linux/instantclient/instantclient-odbc-linuxx64.zip"  \
  && wget -O instantclient-sqlplus "https://download.oracle.com/otn_software/linux/instantclient/instantclient-sqlplus-linuxx64.zip" \
  && wget -O instantclient-tools   "https://download.oracle.com/otn_software/linux/instantclient/instantclient-tools-linuxx64.zip" \
  && wget -O instantclient-sdk     "https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linuxx64.zip" \
  && wget -O instantclient-jdbc    "https://download.oracle.com/otn_software/linux/instantclient/instantclient-jdbc-linuxx64.zip" \
  && for file in basic odbc sqlplus tools sdk jdbc ; do unzip instantclient-$file ; rm -f instantclient-$file ; done \
  && ln -s instantclient_19_6 instantclient \
  && sh -c "echo /opt/oracle/instantclient > /etc/ld.so.conf.d/oracle-instantclient.conf" \
  && ldconfig

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

ENV PATH=$PATH:/usr/local/go/bin
RUN mkdir -p /etc/skel/R/3.6/lib \
  && mkdir -p /etc/skel/.local/bin \
  && mkdir -p /etc/skel/bin \
  && sh -c "echo \"R_LIBS_USER=${R_LIBS_USER-'~/R/3.6/lib'}\" >> /usr/local/lib/R/etc/Renviron" \
  && wget -O /tmp/golang https://storage.googleapis.com/golang/go1.15.5.linux-amd64.tar.gz \
  && tar -C /usr/local -xzf /tmp/golang \
  && rm /tmp/golang \
  && chmod -R 755 /usr/local/go \
  && ln -s /usr/local/go/bin/go /usr/bin/go \
  && ln -s -f /usr/bin/python3 /usr/bin/python \
  && ln -s -f /usr/bin/pydoc3 /usr/bin/pydoc \
  && ln -s -f /usr/bin/pygettext3 /usr/bin/pygettext \
  && ln -s -f /usr/bin/py3versions /usr/bin/pyversions \
  && ln -s -f /usr/bin/py3clean /usr/bin/pyclean \
  && ln -s -f /usr/bin/py3compile /usr/bin/pycompile \
  && curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
  && python /tmp/get-pip.py \
  && sh -c "echo 'export PATH=$PATH' >> /etc/skel/.bashrc "

COPY packages /tmp/packages
RUN xargs -I {} -s -a /tmp/packages -0 install2.r --deps TRUE -n 8 {}

