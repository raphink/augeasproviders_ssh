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

  case $AUGEAS in
    0.10.0)
      VERSION=0.10.0-0ubuntu4
      BASE_URL=http://mirror.optus.net/ubuntu/pool/main/a/augeas
      ;;

    1.0.0)
      VERSION=1.0.0-0ubuntu1~precise1
      BASE_URL=https://launchpad.net/~raphink/+archive/ubuntu/augeas-${AUGEAS}/+files
      ;;

    1.1.0)
      VERSION=1.1.0-0ubuntu1~raphink1~lucid1
      BASE_URL=https://launchpad.net/~raphink/+archive/ubuntu/augeas-${AUGEAS}/+files
      ;;

    1.2.0)
      VERSION=1.2.0-0ubuntu1~precise1
      BASE_URL=https://launchpad.net/~raphink/+archive/ubuntu/augeas-${AUGEAS}/+files
      ;;
  esac

  if [ -n $VERSION ]; then
    wget $BASE_URL/libaugeas-dev_${VERSION}_amd64.deb
    dpkg -x libaugeas-dev_${VERSION}.deb fakeroot/
    wget $BASE_URL/libaugeas0_${VERSION}_amd64.deb
    dpkg -x libaugeas0_${VERSION}.deb fakeroot/
  fi
fi

export LD_LIBRARY_PATH=$PWD/fakeroot/usr/lib/

# Install gems
gem install bundler
bundle install

# Reporting only
bundle show
puppet --version
augtool --version
