#!/bin/bash

#force root
if [ xroot == x$(whoami) ]
then
 echo "Try executing as non root"
 exit
fi

set -e
set -x 

[ -z "$GOROOT" ] && echo '$GOROOT is not defined. Try to install GO or reload bash.' && exit 

mkdir -p $GOPATH/github.com/hyperledger
cd $GOPATH/src/github.com/hyperledger

git clone	https://gerrit.hyperledger.org/r/p/fabric.git

#get samples
cd fabric 
git clone https://github.com/hyperledger/fabric-samples.git

curl -sSL https://goo.gl/Gci9ZX | sudo bash

cd bin
export PATH=$PATH:$(pwd)
echo "export PATH=\$PATH:$(pwd)" >> $HOME/.bashrc

sudo chown -R ubuntu:ubuntu $GOROOT
