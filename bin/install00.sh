#!/bin/bash

# Linux packages
package0="../files/packages_00"
defaultUser="web"

if [ -f "$package0" ]
then
  yum -y install $(cat $package0)	
fi

# The BUILD/MAKE packages aren't part of the CentOS 6 perl default
# cpan helper module
cpan App::cpanminus
/usr/local/bin/cpanm ExtUtils::Install

/bin/id $defautUser 2>/dev/null

echo "Id results: $?" 

if [ $? -eq 0 ] 
then
  echo "User $defaultUser Exists"
else
  echo "Create default user $defaultUser"
  useradd $defaultUser -d "/$defaultUser" -m
  passwd $defaultUser
  visudo  
fi



if [ -d "/$defaultUser" ] 
then
  cd "/$defaultUser"
  echo `pwd`
  mkdir -p {logs,src,etc}
  chown -R $defaultUser:$defaultUser "/$defaultUser"
else
  echo `pwd`
fi






