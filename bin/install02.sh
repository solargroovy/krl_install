#!/bin/bash

# Download and install Apache
apachedist="httpd-2.2.15.tar.gz"
read -e -p "Apache distribution: " -i $apachedist input
apachedist="${input:-$apachedist}"

echo "wget http://archive.apache.org/dist/httpd/$apachedist"
cd ~/src
#wget "http://archive.apache.org/dist/httpd/$apachedist"
#tar -zxvf $apachedist

apachesrc=`expr "$apachedist" : '\(.*\)\.tar'`

echo " root: $apachesrc "

cd $apachesrc
./configure --with-mpm=prefork --prefix=/web --with-included-apr --enable-deflate=shared --enable-expires=shared --enable-headers=shared --enable-dav=shared
make
make install
