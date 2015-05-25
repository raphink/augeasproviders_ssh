#!/bin/bash
set -xe

# Clone submodules in tree
git submodule update --init

if [ -z $AUGEAS ]; then
  # Use latest version of lenses
  cd augeas && git pull origin master
  PKG_VERSION=""
else
  if [ -z $LENSES ]; then
    # Use matching version of lenses
    cd augeas && git fetch && git checkout release-${AUGEAS}
  else
    cd augeas && git fetch && git checkout $LENSES
  fi

  wget https://launchpad.net/~raphink/+archive/ubuntu/augeas-${AUGEAS}/+files/libaugeas-dev_${AUGEAS}-0ubuntu1~precise1_amd64.deb
  dpkg -x libaugeas-dev_${AUGEAS}-0ubuntu1~precise1_amd64.deb fakeroot
  wget https://launchpad.net/~raphink/+archive/ubuntu/augeas-${AUGEAS}/+files/libaugeas0_${AUGEAS}-0ubuntu1~precise1_amd64.deb
  dpkg -x libaugeas0_${AUGEAS}-0ubuntu1~precise1_amd64.deb fakeroot
fi

export LD_LIBRARY_PATH=$PWD/fakeroot

# Install gems
gem install bundler
bundle install

# Reporting only
bundle show
puppet --version
augtool --version
