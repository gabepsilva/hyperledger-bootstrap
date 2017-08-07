#!/bin/bash

set -e
set -x 
# b_msg = bootstrap_message


#force root
if [ xroot != x$(whoami) ]
then
 echo "You must run as root (Hint: Try prefix 'sudo' while executing the script"
 exit
fi


# Install some basic utilities and packages for SDK
apt-get update -qq
apt-get install -y build-essential git make curl unzip libtool apt-transport-https ca-certificates linux-image-extra-$(uname -r) openjdk-8-jdk maven gradle npm tcl tclx tcllib python-dev libyaml-dev python-setuptools python-pip aufs-tools libbz2-dev libffi-dev zlib1g-dev software-properties-common curl git sudo wget libssl-dev libltdl-dev btrfs-tools apparmor python-pytest
apt-get install -y --no-install-recommends erlang-nox erlang-reltool haproxy libicu5. libmozjs185-1.0 openssl cmake apt-transport-https gcc g++ erlang-dev libcurl4-openssl-dev libicu-dev libmozjs185-dev make

pip install --upgrade pip

# ----------------------------------------------------------------
# Install Docker
# ----------------------------------------------------------------

# Storage backend logic
case "${DOCKER_STORAGE_BACKEND}" in
 aufs|AUFS|"")
 DOCKER_STORAGE_BACKEND_STRING="aufs" ;;
 btrfs|BTRFS)
 # mkfs
 apt-get install -y btrfs-tools
 mkfs.btrfs -f /dev/sdb
 rm -Rf /var/lib/docker
 mkdir -p /var/lib/docker
 . <(sudo blkid -o udev /dev/sdb)
 echo "UUID=${ID_FS_UUID} /var/lib/docker btrfs defaults 0 0" >> /etc/fstab
 mount /var/lib/docker

 DOCKER_STORAGE_BACKEND_STRING="btrfs" ;;
 *) echo "Unknown storage backend ${DOCKER_STORAGE_BACKEND}"
 exit 1;;
esac


curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

# Add docker repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update system
apt-get update -qq

# Install docker
apt-get install -y -qq apparmor docker-ce

#"Inslling docker-compose" 
pip install docker-compose
#curl -L https://github.com/docker/compose/releases/download/1.8.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
#chmod +x /usr/local/bin/docker-compose

# Configure docker
DOCKER_OPTS="-s=${DOCKER_STORAGE_BACKEND_STRING} -r=true --api-cors-header='*' -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock ${DOCKER_OPTS}"
sed -i.bak '/^DOCKER_OPTS=/{h;s|=.*|=\"'"${DOCKER_OPTS}"'\"|};${x;/^$/{s||DOCKER_OPTS=\"'"${DOCKER_OPTS}"'\"|;H};x}' /etc/default/docker

service docker restart
usermod -a -G docker $(whoami) # Add user to the docker group

# Test docker
docker run --rm busybox && echo "Docker is good" || echo Docker not OK

# ----------------------------------------------------------------
# Install Golang
# ----------------------------------------------------------------
GO_VER=1.8.3
GO_URL=https://storage.googleapis.com/golang/go${GO_VER}.linux-amd64.tar.gz

# Set Go environment variables needed by other scripts
[ -z "$GOROOT" ] && export GOROOT="/opt/gopath"
[ -z "$GOPATH" ] && export GOPATH=$GOROOT/bin
mkdir -p $GOROOT

export PATH=$PATH:$GOROOT/bin

cat <<EOF >/etc/profile.d/goroot.sh
export GOROOT=$GOROOT
export GOPATH=$GOPATH
export PATH=\$PATH:$GOROOT/bin
EOF

curl -sL $GO_URL | (cd $GOROOT && tar --strip-components 1 -xz)
$GOROOT/bin/go version 


# ----------------------------------------------------------------
# Install NodeJS
# ----------------------------------------------------------------
NODE_VER=6.11.2
NODE_URL=https://nodejs.org/dist/v$NODE_VER/node-v$NODE_VER-linux-x64.tar.gz

 echo $COLOR_GREEN Installing NodeJS $NODE_VER $COLOR_NC

curl -sL $NODE_URL | (cd /usr/local && tar --strip-components 1 -xz )
node -v 



# ----------------------------------------------------------------
# Download Fabric
# ----------------------------------------------------------------
FABRIC_SRC="$GOROOT/src/github.com/hyperledger/fabric/"
mkdir -p $FABRIC_SRC
cd $FABRIC_SRC
#git clone https://github.com/hyperledger/fabric.git $FABRIC_SRC
git clone	https://gerrit.hyperledger.org/r/p/fabric.git $FABRIC_SRC

#fix link
ln -s /opt/gopath/src/ /opt/gopath/bin
#download binaries - plataform specific
#http://hyperledger-fabric.readthedocs.io/en/latest/samples.html
curl -sSL https://goo.gl/iX9dek | bash

#alternativatly you can compile after reboot
#export TEST_PKGS="github.com/hyperledger/fabric/core/ledger/..."
#http://hyperledger-fabric.readthedocs.io/en/latest/dev-setup/build.html
#make unit-test
cd -

# ----------------------------------------------------------------
# Misc tasks
# ----------------------------------------------------------------

# Create directory for the DB
sudo mkdir -p /var/hyperledger

# Update limits.conf to increase nofiles for LevelDB and network connections
sudo cp $FABRIC_SRC/devenv/limits.conf /etc/security/limits.conf

# Configure tools environment
cat <<EOF >/etc/profile.d/tools-devenv.sh
# Expose the devenv/tools in the $PATH
export PATH=\$PATH:$FABRIC_SRC/devenv/tools:$FABRIC_SRC/build/bin:$FABRIC_SRC/bin
export CGO_CFLAGS=" "
EOF

# Set our shell prompt to something less ugly than the default from packer
# Also make it so that it cd's the user to the fabric dir upon logging in
cat <<EOF >> ~/.bashrc
export FABRIC_SRC="$GOROOT/src/github.com/hyperledger/fabric/"
DEVENV_REVISION="cd \$FABRIC_SRC; git rev-parse --short HEAD 2> /dev/null"
PS1="\u@hyperledger-devenv:\\\$(eval \$DEVENV_REVISION):\w$ "
cd $GOROOT/src/github.com/hyperledger/fabric/
EOF

# ----------------------------------------------------------------
# Install Behave
# ----------------------------------------------------------------
pip install behave
pip install nose

# updater-server, update-engine, and update-service-common dependencies (for running locally)
pip install -I flask==0.10.1 python-dateutil==2.2 pytz==2014.3 pyyaml==3.10 couchdb==1.0 flask-cors==2.0.1 requests==2.4.3 pyOpenSSL==16.2.0 pysha3==1.0b1

# Python grpc package for behave tests
# Required to update six for grpcio
pip install --ignore-installed six
pip install --upgrade 'grpcio==1.0.4'

# Pip packages required for some behave tests
pip install ecdsa python-slugify b3j0f.aop
