#!/bin/bash
# Final script to make sure environment is up and running

force=0
if [[ "$1" =  "-f" ]] || [[ "$1" = "--force" ]]
then
  echo "force restart"
  force=1
fi


# MongoDB service

sudo /sbin/service mongod status
status=$?

#echo "Mongo Status: $status"
if [[ "$status" -eq "0" ]]  
then
  if [ "$force" -eq "1" ]
  then
    echo "Force restart of MongoDB"
    sudo /sbin/service mongod restart &> /dev/null
  fi
else
  sudo /sbin/service mongod start
fi


# Memcached service

sudo /sbin/service memcached status
status=$?

#echo "Memcached Status: $status"
if [[ "$status" -eq "0" ]]  
then
  if [ "$force" -eq "1" ]
  then
    echo "Force restart of Memcached"
    sudo /sbin/service memcached restart &> /dev/null
  fi
else
  sudo /sbin/service memcached start
fi

# Antlr Parser

ptext=`perl -MInline::Java::Server=status`

status=`expr "$ptext" : '.*not running'`
#echo "JVM Status:$? :  $status"
#echo "Ptest: $ptext"

if [[ "$status" -gt "0" ]] 
then
  echo "JVM Stopped"
  perl -MInline::Java::Server=start
elif [ "$force" -eq "1" ]
then
  echo "Force JVM restart"
  perl -MInline::Java::Server=restart
else
  ppid=`lsof | grep -m1 InlineJavaServer | awk  '{ print $2 }'`
  echo "Antlr parser (pid $ppid) is running..."
fi


# Apache http server

sudo /sbin/service httpd status
status=$?

#echo "Apache Status: $status"
if [[ "$status" -eq "0" ]]  
then
  if [ "$force" -eq "1" ]
  then
    echo "Force restart of httpd"
    sudo /sbin/service httpd restart &> /dev/null
  fi
else
  sudo /sbin/service httpd start
fi
