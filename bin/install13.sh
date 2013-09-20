#!/bin/bash

repo="git://github.com:kre/common.git"
repod='common'

default_dir="/web/src"

read -e -p "Default directory for common rulesets: " -i $default_dir input
default_dir=${input:-$default_dir}

if [[ ! -d $default_dir ]]
then
  mkdir -p $default_dir
fi


# Checkout the KRE from git
cd $default_dir

if [[ -d $repod ]]
then
  echo "Repo $repo already found"
  pushd $repod
  git checkout master
  git pull origin master
  popd  
else
  # create the KRE remote repo
  echo "Check out KRE common rulesets from $repo"
  git clone $repo
fi

# update config file
file="/web/etc/kns_config.yml"
fqp="$default_dir/$repod/rulesets"

if [[ -d $fqp ]]
then
  # replace repository source
  echo $fqp
  #perl -pi -e "s/^RULE_REPOSITORY:.*/RULE_REPOSITORY: $fqp/" $file
  perl -pi -e "s#^RULE_REPOSITORY:.*#RULE_REPOSITORY: $fqp#" $file
fi


