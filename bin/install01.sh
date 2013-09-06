#!/bin/bash

# modify the .bashrc file

bfile="/web/.bashrc"

/usr/bin/perl -ni -e 'print unless /KOBJ_ROOT/' $bfile
/usr/bin/perl -ni -e 'print unless /WEB_ROOT/' $bfile
/usr/bin/perl -ni -e 'print unless /JAVA_HOME/' $bfile

echo "export KOBJ_ROOT=/web/lib/perl"  >> $bfile
echo "export WEB_ROOT=/web" >> $bfile
echo "export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk.x86_64" >> $bfile
