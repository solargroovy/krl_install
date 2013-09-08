#!/bin/bash

# Download and install IP location database
cd ~/src
file="subversion-1.4.6"

wget "http://subversion.tigris.org/downloads/$file.tar.gz"

tar -zxvf "$file.tar.gz"

cd $file

./configure --prefix=/usr/local/subversion --with-apr=/web/src/httpd-2.2.15/srclib/apr --with-apr-util=/web/src/httpd-2.2.15/srclib/apr-util/ --with-apxs=/web/bin/apxs
make
sudo make install


