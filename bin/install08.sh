#!/bin/bash

# Install MongoDB

# ask if local installation
local="y"
read -e -p "Install MongoDB locally: " -i $local input
local="${input:-$local}"


# check for MongoDB yum repo definitions
file="/etc/yum.repos.d/10gen.repo"

if [[ ! -f $file && $local -eq "y" ]]
then
  sudo ex $file <<__EOF__
:a
[10gen]
name=10gen Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64
gpgcheck=0
enabled=1
.
:wq
__EOF__
  sudo yum update
else
  echo "Repo definition $file exists"
fi

echo "Local $local"
if [[ $local -eq "y" ]] 
then
  #yum info mongo-10gen
  sudo yum –y install mongo-10gen 
  sudo yum -y install mongo-10gen-server

  echo "Edit config for locally hosted mongo"
  file="/etc/mongod.conf"
  sudo perl -pi -e 's/^#\s*nojournal/nojournal/' $file
  sudo perl -pi -e 's/^#\s*noprealloc/noprealloc/' $file
  grep nojour $file
  grep noprealloc $file
  sudo /sbin/service mongod status &> /dev/null

  status=$?

  if [[ $status > 0 ]]
  then
    sudo /sbin/service mongod start
  fi
fi

mongos="localhost"

if [[ ! $local -eq "y" ]]
then
  read -e -p "MongoDB server: " -i $mongos input
  local="${input:-$mongos}"
fi

orgname="kynetx"
read -e -p "Org name: " -i $orgname input

for mongojs in ../files/mongo*.js
do
  echo $mongojs
  mongo --eval "mserver='$mongos';orgname='$orgname'" $mongojs
done


