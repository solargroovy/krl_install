#!/bin/bash

# Download and install PERL modules that have demonstrated CPAN 
# complications

cd ~/src
perlsrc="perlsrc"
mkdir -p "$perlsrc"
pushd $perlsrc

# Devel::Size
# Was it picked up from CPAN

module="Devel::Size"

perldoc -l $module &> /dev/null

status=$?

if [ $status == 1 ]
then
  file="perl-Devel-Size-0.71-1.el6.rf.x86_64.rpm"
  echo "Install $file from rpm"
  wget "ftp://ftp.univie.ac.at/systems/linux/dag/redhat/el6/en/x86_64/dag/RPMS/$file"
  if [ -f $file ]
  then
    sudo yum install $file
  fi
else
  echo "Found $module"
fi

# Crypt::OpenSSL::X509
popd


pwd

module=Crypt::OpenSSL::X509

perldoc -l $module &> /dev/null

status=$?

if [ $status == 1 ]
then
  file="Crypt-OpenSSL-X509-1.6"
  echo "Install $file from source"
  wget "http://search.cpan.org/CPAN/authors/id/D/DA/DANIEL/$file.tar.gz"
  tar -zxvf "$file.tar.gz"
  cd $file
  perl ./Makefile.pl
  make
  sudo make install
else
  echo "Found $module"
fi

# Test-WWW-Mechanize
cd $perlsrc
pwd

module="Test::WWW::Mechanize"

perldoc -l $module &> /dev/null

status=$?

if [ $status == 1 ]
then
  file="Test-WWW-Mechanize-1.30"
        #Test-WWW-Mechanize-1.30
  echo "Install $file from source"
  wget "http://search.cpan.org/CPAN/authors/id/P/PE/PETDANCE/$file.tar.gz"
  tar -zxvf "$file.tar.gz"
  cd $file
  pwd

  perl ./Makefile.[pP][lL]
  make
  sudo make install
else
  echo "Found $module"
fi


# Apache2::Request
popd

module="Apache2::Request"

perldoc -l $module &> /dev/null

status=$?

if [ $status == 1 ]
then
  file="libapreq2-2.12"
  echo "Install $file from source"
  wget "http://mirrors.axint.net/apache/httpd/libapreq/$file.tar.gz"
  tar -zxvf "$file.tar.gz"
  cd $file
  perl ./Makefile.[pP][lL] --with-apache2-apxs=/web/bin/apxs
  make
  sudo make install
else
  echo "Found $module"
fi
# Apache::Session::Memcached
popd

module="Apache::Session::Memcached"

perldoc -l $module &> /dev/null

status=$?

if [ $status == 1 ]
then
  file="Apache-Session-Memcached-0.03"
  echo "Install $file from source"
  wget "http://search.cpan.org/CPAN/authors/id/E/EN/ENRYS/$file.tar.gz"
  tar -zxvf "$file.tar.gz"
  cd $file
  perl ./Makefile.[pP][lL]
  make
  sudo make install
else
  echo "Found $module"
fi

# Inline::Java
popd

module="Inline::Java"

perldoc -l $module &> /dev/null

status=$?

if [ $status == 1 ]
then
  file="Inline-Java-0.52"
  echo "Install $file from source"
  wget "http://search.cpan.org/CPAN/authors/id/P/PA/PATL/$file.tar.gz"
  tar -zxvf "$file.tar.gz"
  cd $file
  perl ./Makefile.[pP][lL] J2SDK=/usr/lib/jvm/java-1.6.0-openjdk.x86_64 BUILD_JNI=0
  make
  sudo make install
else
  echo "Found $module"
fi


