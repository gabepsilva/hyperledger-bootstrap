#!/bin/bash

#force root
if [ xroot != x$(whoami) ]
then
 echo "You must run as root"
 exit
fi

set -e
set -x


apt-get update

apt-get install -y \
  linux-image-extra-$(uname -r) \
  linux-image-extra-virtual

apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common
  
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

apt-key fingerprint 0EBFCD88

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
   
apt-get update

sudo apt-get install -y docker-ce

apt-get install -y python-pip
pip install --upgrade pip

pip install docker-compose

docker run hello-world
docker-compose -version


