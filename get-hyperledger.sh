#!/bin/bash

#force root
if [ xroot == x$(whoami) ]
then
 echo "Try executing as non root"
 exit
fi


[ -z "$GOROOT" ] && echo '\$GOROOT is not defined. Try to install GO or reload bash.' && exit 

cd $GOPATH/src
mkdir -p $GOPATH/src/github.com/hyperledger
cd $GOPATH/src/github.com/hyperledger

git clone	https://gerrit.hyperledger.org/r/p/fabric.git

cd fabric 

