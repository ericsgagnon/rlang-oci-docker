#!/bin/bash

wd=$DOCKER_BUILD_DIRECTORY

# configure new user directories:
mkdir -p \
    /etc/skel/.local/bin   \
    /etc/skel/.local/share \
    /etc/skel/.config      \
    /etc/skel/.cache

cp $wd/mkdir-r-lib.sh /etc/profile.d/mkdir-r-lib.sh \
    && sh -c "echo 'export PATH=$PATH' >> /etc/skel/.bashrc "

mkdir -p /etc/skel/.local/share/R/$R_MAJOR_MINOR/lib  \
    && cp $wd/.Rprofile /etc/skel/.config/R/.Rprofile \
    && cp $wd/.Renviron /etc/skel/.config/R/.Renviron \
    && echo "R_LIBS_USER=${R_LIBS_USER-'~/.local/share/R/"$R_MAJOR_MINOR"/lib'}"    >> /usr/local/lib/R/etc/Renviron \
    && echo "R_MAJOR_MINOR=$R_MAJOR_MINOR"                                          >> /usr/local/lib/R/etc/Renviron \
    && echo "R_VERSION=$R_VERSION"                                                  >> /usr/local/lib/R/etc/Renviron \
    && echo "R_ENVIRON_USER=$R_ENVIRON_USER"                                        >> /usr/local/lib/R/etc/Renviron \
    && echo "R_PROFILE_USER=$R_PROFILE_USER"                                        >> /usr/local/lib/R/etc/Renviron

# make skel


# copy files to skel

# configure Renviron

# setup login scripts that make sure specific directories and files exist in 
# each user's home directory


