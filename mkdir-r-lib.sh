#! /bin/bash

r_lib_dir=~/.local/share/R/$R_MAJOR_MINOR/lib

if [ ! -d $r_lib_dir ] ; then
        mkdir -p $r_lib_dir ;
        echo "created directory: $r_lib_dir, please restart your session" ;
        # else
        # echo "directory: $r_lib_dir already exists" ;
fi
