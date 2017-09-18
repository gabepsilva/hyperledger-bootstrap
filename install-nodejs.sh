#!/bin/bash

#force root
if [ xroot != x$(whoami) ]
then
 echo "You must run as root"
 exit
fi



set -e
set -x 


NODE_VER=6.11.2
NODE_URL=https://nodejs.org/dist/v$NODE_VER/node-v$NODE_VER-linux-x64.tar.gz

curl -sL $NODE_URL | (cd /usr/local && tar --strip-components 1 -xz )
node -v 
npm -v 
