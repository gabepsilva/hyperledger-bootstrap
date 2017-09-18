#!/bin/bash

#force root
if [ xroot != x$(whoami) ]
then
 echo "You must run as root"
 exit
fi

set -e
set -x 


apt-get install -y python-pip
pip install --upgrade pip

pip install behave nose
pip install -I flask==0.10.1 python-dateutil==2.2 pytz==2014.3 pyyaml==3.10 couchdb==1.0 flask-cors==2.0.1 pyOpenSSL==16.2.0 pysha3==1.0b1 grpcio==1.0.4

#PIP packages required for some behave tests
pip install urllib3 ndg-httpsclient pyasn1 ecdsa python-slugify grpcio-tools jinja2 b3j0f.aop six

#requests==2.4.3
