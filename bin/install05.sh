#!/bin/bash

# Download and install cronolog
cd ~/src
file="cronolog-1.6.2"

wget "http://cronolog.org/download/$file.tar.gz"
tar -zxvf "$file.tar.gz"
cd $file

./configure --prefix=/web
make
sudo make install

