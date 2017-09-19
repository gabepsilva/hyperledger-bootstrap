#!/bin/bash

# Usage:
#
# ./prereqs-ubuntu.sh
#
# User must then logout and login upon completion of script
#

# Exit on any failure
set -e


#Force non root
if [ xroot == x$(whoami) ]
then
 echo "Try executing as non root"
 exit
fi

# Array of supported versions
declare -a versions=('trusty' 'xenial' 'yakkety');

# check the version and extract codename of ubuntu if release codename not provided by user
if [ -z "$1" ]; then
    source /etc/lsb-release || \
        (echo "Error: Release information not found, run script passing Ubuntu version codename as a parameter"; exit 1)
    CODENAME=${DISTRIB_CODENAME}
else
    CODENAME=${1}
fi

# check version is supported
if echo ${versions[@]} | grep -q -w ${CODENAME}; then
	echo ;
	echo ;
    echo "Bootstrapping Hyperledger prereqs for Ubuntu ${CODENAME}"
	echo "--------------------------------------------------------------"
	sudo echo ; 
	echo ;
	
	
else
    echo "Error: Ubuntu ${CODENAME} is not supported"
    exit 1
fi

echo ;
echo ;
echo "##################################################"
echo "# Installing Git, Curl, pip and dependencies     #"
echo "##################################################"
echo ;
echo ;
sudo apt-add-repository -y ppa:git-core/ppa
sudo apt-get update

sudo apt-get install -y curl git python-pip build-essential libssl-dev libltdl-dev
sudo pip install --upgrade pip

#PIP packages required for some behave tests
sudo pip install urllib3 ndg-httpsclient pyasn1 ecdsa python-slugify grpcio-tools jinja2 b3j0f.aop six
sudo pip install behave nose
sudo pip install -I flask==0.10.1 python-dateutil==2.2 pytz==2014.3 pyyaml==3.10 couchdb==1.0 flask-cors==2.0.1 pyOpenSSL==16.2.0 pysha3==1.0b1 grpcio==1.0.4 requests==2.4.3


echo ;
echo ;
echo "##################################################"
echo "#              Installing docker                 #"
echo "##################################################"
echo ;
echo ;
# Add Docker repository key to APT keychain
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Update where APT will search for Docker Packages
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list

# Update package lists
sudo apt-get update

# Verifies APT is pulling from the correct Repository
sudo apt-cache policy docker-ce

# Install kernel packages which allows us to use aufs storage driver if V14 (trusty/utopic)
if [ "${CODENAME}" == "trusty" ]; then
    echo "# Installing required kernel packages"
    sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
fi

# Install Docker
echo "# Installing Docker"
sudo apt-get -y install docker-ce

# Add user account to the docker group
sudo usermod -aG docker $(whoami)

# Install docker compose
echo "# Installing Docker-Compose"
sudo curl -L "https://github.com/docker/compose/releases/download/1.13.0/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


echo ;
echo ;
echo "##################################################"
echo "#              Installing GO                     #"
echo "##################################################"
echo ;
echo ;
# Install GO
GO_VER=1.9
GO_URL=https://storage.googleapis.com/golang/go${GO_VER}.linux-amd64.tar.gz

export GOROOT="${HOME}/go${GO_VER}"
export GOPATH=$GOROOT
export PATH=$PATH:$GOROOT/bin
mkdir -p $GOROOT

cat <<EOF >> ${GOROOT}/setenv
export GOROOT=$GOROOT
export GOPATH=$GOPATH
export PATH=\$PATH:$GOROOT/bin
EOF


curl -sL $GO_URL | (cd $GOROOT && tar --strip-components 1 -xz) 

$GOROOT/bin/go version

echo ;
echo ;
echo "##################################################"
echo "#              Downloading Fabric                #"
echo "##################################################"
echo ;
echo ;
[ -z "$GOROOT" ] && echo '$GOROOT is not defined. Try to install GO or reload bash.' && exit 

mkdir -p $GOPATH/src/github.com/hyperledger
cd $GOPATH/src/github.com/hyperledger

git clone https://gerrit.hyperledger.org/r/p/fabric.git 

#get samples
cd fabric 
git clone https://github.com/hyperledger/fabric-samples.git 

curl -sSL https://goo.gl/Gci9ZX | sudo bash 


export PATH=$PATH:$(pwd)/bin
echo "export PATH=\$PATH:$(pwd)/bin" >> ${GOROOT}/setenv
	
sudo chown -R ubuntu:ubuntu $GOROOT

cat ${GOROOT}/setenv >> ${HOME}/.bashrc
sudo sh -c "cat ${GOROOT}/setenv >> /root/.bashrc"



echo ;
echo ;
echo "##################################################"
echo "#              Installing Node                   #"
echo "##################################################"
echo ;
echo ;
# Execute nvm installation script
echo "# Executing nvm installation script"
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash

# Set up nvm environment without restarting the shell
export NVM_DIR="${HOME}/.nvm"
[ -s "${NVM_DIR}/nvm.sh" ] && . "${NVM_DIR}/nvm.sh"
[ -s "${NVM_DIR}/bash_completion" ] && . "${NVM_DIR}/bash_completion"

# Install node
echo "# Installing nodeJS"
nvm install --lts

# Configure nvm to use version 6.9.5
nvm use --lts
nvm alias default 'lts/*'

# Install the latest version of npm
echo "# Installing npm"
npm install npm@latest -g

# Ensure that CA certificates are installed
sudo apt-get -y install apt-transport-https ca-certificates

echo ;
echo ;
echo "##################################################"
echo "#              Hyperledger Composer DEV env      #"
echo "##################################################"
echo ;
echo ;

npm install -g composer-cli
npm install -g generator-hyperledger-composer
npm install -g composer-rest-server
npm install -g yo
npm install -g composer-playground

mkdir ~/fabric-tools && cd ~/fabric-tools
curl -O https://raw.githubusercontent.com/hyperledger/composer-tools/master/packages/fabric-dev-servers/fabric-dev-servers.tar.gz

tar xvzf fabric-dev-servers.tar.gz


echo ;
echo ;
echo 'Docker clean up: '
echo "--------------------------------------------------------------"
echo ;
echo 'docker kill $(docker ps -q)'
echo 'docker rm $(docker ps -aq)'
echo 'docker rmi $(docker images dev-* -q)'


echo ;
echo ;
echo 'Starting and stopping Hyperledger Composer: '
echo "--------------------------------------------------------------"
echo ;
echo 'cd ~/fabric-tools'
echo './downloadFabric.sh'
echo './startFabric.sh'
echo './createComposerProfile.sh'
echo ;
echo 'cd ~/fabric-tools'
echo './stopFabric.sh'
echo './teardownFabric.sh'
echo ;
echo ;

# Print installation details for user
echo ''
echo 'Installation completed, versions installed are:'
echo "--------------------------------------------------------------"
echo ;
echo -n 'Node:           '
node --version
echo -n 'npm:            '
npm --version
echo -n 'Docker:         '
docker --version
echo -n 'Docker Compose: '
docker-compose --version
echo -n 'Python:         '
python -V

echo -n 'Go:           '
$GOROOT/bin/go version


# Print reminder of need to logout in order for these changes to take effect!
echo ''
echo "Please logout then login before continuing."
