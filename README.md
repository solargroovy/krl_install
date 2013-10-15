krl_install
===========

This install process has been verified on 64 bit Centos 6.2.  It consists of a number of shell and perl scripts that should be executed in order numerical order; ie: start with install00.sh

Other versions and flavors of *nix should be valid, but the library and file dependencies may vary slightly.

Where possible, the intention is that you could run a script multiple times, but the install process should only require a single execution.

INSTALL
=======

Start with a clean installation of Centos 6.2 (64 bit).  

The first install file installs the base linux packages and creates the KRE default user so it will need to be run as root

  # ./install00.sh

If the default user does not already exist, it will be created and the script will open a visudo session to allow the rest of the scripts to install (where required) with sudo.

Add the sudo entries for the default user:
  web     ALL=(ALL)       ALL
  web     ALL=NOPASSWD: /bin/chown web, /bin/gzip, /bin/mv, /etc/init.d/httpd, /sbin/service httpd,  /web/lib/perl/bin/update_cpan.pl /web/lib/perl

It is probably best to log out of the root at this point and login as the default user (web)

As (web), cd to the krl_install repository

  $ cd bin

Start running the install scripts in the numerical order.

  $ ./install01.sh

This script configures the environment for the default user

  $ ./install02.sh

This script will install the correct version of Apache.  It is important to configure and install Apache as (web).  The default is to use the MPM *prefork*, if you would like to use a more recent MPM, you must compile that into the Apache executable.

  (The script install00.sh should have created a ~/src directory for your default user.  This is where the third party resources will be downloaded)

  $ ./install03.sh

After Apache is built, the Apache module mod_perl will be installed

  $ ./install04.sh

The next resource is GeoIP, which is a module to identify the rough location of a user by the associated IP address.

  $ ./install05.sh

Cronolog is used to rotate the Apache log files.

  $ ./install06.sh

'cpanm' is a small footprint PERL module installation tool.  Required PERL modules are installed if there is no corresponding module found vi perldoc -l.  It may be necessary to update the version of MIME::Base64 that is distributed with the Centos PERL.  During the authorization setup (test00.pl), if you get an error stating that "encode_base64url" is not exported by the MIME::Base64 module, re-install the MIME::Base64 module and re-run (test00.pl)

  $ ./install07.sh

The GeoIP perl module is downloaded and installed separately

  $ ./install08.sh

This script installs a local version of MongoDB.  If you already have an instance of MongoDB that you will be using, you can skip this step.  This script will prompt you for simple configuration information for MongoDB. Indexes and collections are created from the files/mongo*.js files.

  $ ./install09.sh

Installs subversion.  Subversion is deprecated in favor of using git for repositories, but there are still some library dependencies that need to be removed

  $ ./install10.sh

Checks out and installs the KRE libraries.  Part of the install process compiles the KRL parser and starts the PERL/Java jvm

  $ ./install11.pl

Configures and installs the log file for Apache and log4perl. The default is to write the log files to /web/logs

  $ ./install12.pl

Creates the kns_config.yml file which acts as the config for the entire KRE. Defaults are suggested. If you do not understand what an entry is for, it is best that you stick with the default

  $ ./install13.sh

Installs a separate git repository for common KRE rulesets required for testing. As more smoke tests are configured, rulesets will be added to this repository. This is a file based repository.

  $ ./install99.sh

The final install script, ensures that all components are running (MongoDB, JVM, Memcached, Apache) so the test scripts can be run.

Testing
=======

  $ ./test00.pl

Basic test of connectivity and the authorization/account system. If this does not pass, go back over the install process and verify your steps

  $ ./test01.pl

Before the regular smoke tests can be run, specific testing rulesets must be installed.  Currently, this expects the file repository that was created by (install13.sh).  The list of rulesets required are defined in files/rulesets.dat. If you add a ruleset to the file, you should be able to use this script to install a ruleset to your KRE instance.  This may be handy until you can implement your own repository manager with the RSM module.  Duplicate rulesets can not be created, so it should be okay to run this script any time the list updates, but the RSM module will generate warnings.  Parse the output of this script carefully so you can tell whether there is a problem sourcing a new ruleset or a duplicate was found.

  
