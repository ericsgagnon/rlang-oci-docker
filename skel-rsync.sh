#!/bin/bash

# this script propagates /etc/skel to user home directories 
# when logging in. It won't overwrite existing files, but 
# will replace deleted files if the exist in /etc/skel

rsync -v -a --ignore-existing /etc/skel/ ~/
