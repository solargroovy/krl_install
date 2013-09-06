#!/bin/bash

# Linux packages
package1="../files/packages_01"
list=`cat $package1`
sudo ls &> /dev/null
if [ -f "$package1" ]
then
  for file in $list
  do
    perldoc -l $file &> /dev/null
    status=$?
    echo "$file $status"
    if [ $status == 1 ] 
    then
      echo "install $file"
      sudo /usr/local/bin/cpanm $file
    fi
  done
fi

#/usr/local/bin/cpanm ExtUtils::Install

