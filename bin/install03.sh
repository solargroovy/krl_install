#!/bin/bash

# Download and install modperl
cd ~/src
modp="mod_perl-2.0-current"

wget "http://perl.apache.org/dist/$modp.tar.gz"

tar -zxvf "$modp.tar.gz"

for directory in mod_perl*
do
  if [ -d "$directory" ]
  then
    cd "$directory"
    pwd
    if [ ! -e /usr/lib64/libgdbm.so ]
    then
      if [ -e /usr/lib64/libgdbm.so.2.0.0 ]
      then
        sudo ln -s /usr/lib64/libgdbm.so.2.0.0 /usr/lib64/libgdbm.so
      fi
    fi
    perl Makefile.PL MP_APXS=/web/bin/apxs
    make
    sudo make install
    break
  fi
done
