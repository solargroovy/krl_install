#!/bin/bash
. ./functions.sh
repo="git://github.com/kre/Kinetic-Rules-Engine.git"
repod='Kinetic-Rules-Engine'

# Checkout the KRE from git
cd ~/lib

if [[ -d $repod ]]
then
  echo "Repo $repo already found"
  pushd $repod
  git checkout master
  git pull origin master
  popd  
else
  # create the KRE remote repo
  echo "Check out KRE repository from $repo"
  git clone $repo
fi

if [[ ! -h perl ]]
then
  ln -s $repod perl
fi

pushd /web/lib/perl/parser
(./buildjava.sh &>/dev/null) &
spinner $!

# Link the parser control file
control="kns_jvm"
if [[ ! -h "/usr/bin/$control" ]]
then
  sudo ln -s "/web/lib/perl/bin/$control" "/usr/bin/$control"
fi

# Okay if the stop fails
/usr/bin/perl -MInline::Java::Server=stop >& /dev/null;

# Check that the parser runs
/usr/bin/perl -MInline::Java::Server=start >& /dev/null;
status=$?

if [[ $status == 0 ]]
then
  echo "Parser started"
else
  echo "Parser not started"
fi
echo "Parser start: $status"
