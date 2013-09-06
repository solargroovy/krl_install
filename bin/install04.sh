#!/bin/bash

# Download and install IP location database
cd ~/src
file="GeoIP-1.4.3"

wget "http://geolite.maxmind.com/download/geoip/api/c/$file.tar.gz"

tar -zxvf "$file.tar.gz"

cd $file

./configure --prefix=/web
make
sudo make install

geocountry="GeoIP.dat"
geocity="GeoLiteCity.dat"

mkdir newdata
cd newdata

wget "http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/$geocountry.gz"
gunzip "$geocountry.gz"
sudo cp $geocountry /usr/local/share

wget "http://geolite.maxmind.com/download/geoip/database/$geocity.gz"
gunzip "$geocity.gz"
sudo cp $geocity /usr/local/share/GeoIPCity.dat


