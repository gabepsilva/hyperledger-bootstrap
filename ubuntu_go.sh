#!/bin/bash

#force root
if [ xroot == x$(whoami) ]
then
 echo "Try executing as non root"
 exit
fi

set -e
set -x

GO_VER=1.9
GO_URL=https://storage.googleapis.com/golang/go${GO_VER}.linux-amd64.tar.gz

export GOROOT="${HOME}/go${GO_VER}"
export GOPATH=$GOROOT/src
export PATH=$PATH:$GOROOT/bin
mkdir -p $GOROOT

cat <<EOF >> ${HOME}/.bashrc
export GOROOT=$GOROOT
export GOPATH=$GOPATH
export PATH=\$PATH:$GOROOT/bin
EOF

curl -sL $GO_URL | (cd $GOROOT && tar --strip-components 1 -xz)
$GOROOT/bin/go version 

