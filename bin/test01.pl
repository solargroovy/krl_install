#!/usr/bin/perl -w
#
# This file is part of the Kinetic Rules Engine (KRE)
# Copyright (C) 2007-2011 Kynetx, Inc. 
#
# KRE is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
#
use lib qw(
  /web/lib/perl
  ./perl 
  );
use strict;

use Test::More;
use Test::Deep;
use Data::Dumper;
use MongoDB;
use Cache::Memcached;
use Benchmark ':hireswallclock';
use Clone qw(clone);

# most Kyentx modules require this
use Log::Log4perl qw(get_logger :levels);
Log::Log4perl->easy_init($INFO);
Log::Log4perl->easy_init($DEBUG);

use Kynetx::Test qw/:all/;
use Kynetx::Configure;
use Kynetx::MongoDB qw(:all);
use Kynetx::Memcached;
use Kynetx::FakeReq;
use Kynetx::Persistence::KEN;

use ConfMaker qw( :all );
my $logger = get_logger();
my $num_tests = 0;

use constant DEF_OWN => '_web_';

my $uuid_re = "^[A-F|0-9]{8}\-[A-F|0-9]{4}\-[A-F|0-9]{4}\-[A-F|0-9]{4}\-[A-F|0-9]{12}\$";

Kynetx::Configure::configure();

Kynetx::MongoDB::init();

Kynetx::Memcached->init();

my ($result,@results,$description,$expected,$args);

my $dict_path = "/usr/share/dict/words";
my @DICTIONARY;
open DICT, $dict_path;
@DICTIONARY = <DICT>;

##############################################################
#
# Create the request environment
#
##############################################################

my ($my_req_info,$r,$rule_env,$rid,$rule_name,$js,$session,$username);
my ($password,$anon);
$my_req_info = Kynetx::Test::gen_req_info($rid);
$rule_env = Kynetx::Test::gen_rule_env();
$rid = "initial_setup";
$rule_name = "foo";
$r = Kynetx::Test::configure();
$session = Kynetx::Test::gen_session($r,$rid);
$anon = Kynetx::Persistence::KEN::get_ken($session,$rid);

$username =  $DICTIONARY[rand(@DICTIONARY)];
chomp($username);

$password =  $DICTIONARY[rand(@DICTIONARY)];
chomp($password);


note("Ruleset installation");


############################################################
#
# Prepare admin environment 
#
##############################################################
my ($system_key,$keys,$root_env);
my ($test_user,$admin_ken);

use Kynetx::Modules::PCI;
use Kynetx::Persistence::KPDS qw(:all);

subtest 'Admin Environment' => sub {
  $description="Create temporary system key";
  $system_key = Kynetx::Modules::PCI::create_system_key();
  isnt($system_key,undef,$description);

  $description="Check system key";
  $result = Kynetx::Modules::PCI::check_system_key($system_key);
  is($result,1,$description);

  $description = "Make sure key works for PCI module";
  $keys = { 'root' => $system_key };
  ($js, $root_env) =  Kynetx::Keys::insert_key(
    $my_req_info,
    $rule_env,
    'system_credentials',
    $keys);

  $description="PCI module authorization";
  $result = Kynetx::Modules::PCI::pci_authorized($my_req_info,$root_env,$session,$rule_name,"foo",[]);
  is($result,1,$description);

  $description="Create a test user";
  $test_user = Kynetx::Test::gen_user($my_req_info,$root_env,$session,$username);
  isnt($test_user,undef,$description);
};
$num_tests++;

my ($ruleset_owner,$owner_ken,$owner_eci);


$ruleset_owner = Kynetx::Configure::get_config("DEFAULT_RULESET_OWNER") || DEF_OWN;
$owner_ken = Kynetx::Persistence::KEN::ken_lookup_by_username($ruleset_owner);

if ($owner_ken) {
  note("Ruleset owner exists");
  $owner_eci = Kynetx::Persistence::KToken::get_default_token($owner_ken);
} else {
  note("Create default owner for rulesets");
  subtest 'Default Owner' => sub {
    my $args = {
      "username" => $ruleset_owner,
      "firstname" => "Default",
      "lastname" => "Ruleset Owner",
      "password" => "*"
    };
    my $account = Kynetx::Modules::PCI::new_account($my_req_info,$root_env,$session,$rule_name,"foo",[$args]);
    $description="Account created";
    isnt($account,undef,$description);
  
    $description="Get owner cid";
    $owner_eci = $account->{'cid'};
    cmp_deeply($owner_eci,re(qr/$uuid_re/),$description);
    note("ECI: $owner_eci");

    $description="Get owner KEN";
    $owner_ken = Kynetx::Persistence::KEN::ken_lookup_by_token($owner_eci);
    isnt($owner_ken,undef,$description);
  };
  $num_tests++;
}

##############################################################
#
# RULESETS
#
##############################################################
use Kynetx::Modules::RSM;
use Kynetx::Persistence::Ruleset;

my $ruleset_list = "../files/rulesets.dat";
if (-r $ruleset_list) {
  my $r_type = Kynetx::Configure::get_config("RULE_REPOSITORY_TYPE");
  my $repo = Kynetx::Configure::get_config("RULE_REPOSITORY");
  my $uri_prefix;
  if ($r_type eq "file") {
    $uri_prefix = "file://" ;
    #$uri_prefix = "file://" . $repo . '/';
  }
  my $fh = IO::File->new();
  $fh->open($ruleset_list);
  while (<$fh>) {
    my $entry = $_;
    note("Line: $entry");
    my ($fqrid,$rfile,$desc) = split(/,/,$entry);
    my ($rid,$ver) = split(/\./,$fqrid);
    my $rid_info = Kynetx::Rids::mk_rid_info($my_req_info,$rid,{'version'=>$ver});
    my $ruleset_info = Kynetx::Persistence::Ruleset::get_ruleset_info($fqrid);
    if (defined $ruleset_info) {
      note("Ruleset exists: ", explain $ruleset_info);
    } else {
      subtest "Create $rid" => sub {
        my $args = [$rid];
        my $uri = $uri_prefix . $rfile;
        my $mods;
        my $vars;
        my $config = {
          'owner' => $owner_eci,
          'uri' => $uri
        };
        note("Create $rid");
        $result = Kynetx::Modules::RSM::do_create($my_req_info,$root_env,$session,$config,$mods,$args,$vars);
        note("Create result: ", explain $result);
        # Flush the cache so we do a fresh lookup on the ruleset
        $args = [$fqrid];
        Kynetx::Modules::RSM::do_flush($my_req_info,$root_env,$session,$config,$mods,$args,$vars);
        my $status = Kynetx::Modules::RSM::do_validate($my_req_info,$root_env,$session,$config,$mods,$args,$vars);
        note("Status: ", explain $status);
      };
    }
    my $args = [$rid];
    my $uri = $uri_prefix . $rfile;

  }
}

done_testing($num_tests);

##############################################################
#
# CLEANUP
#
##############################################################
if ($test_user) {
  Kynetx::Test::flush_test_user($test_user,$username);
}

# anonymous kens are reused by the test environment by default
# delete the session ken if your test causes multiple
# anonymous KENs to be created
#if ($anon) {
#Kynetx::Persistence::KEN::delete_ken($anon);
#}

# /CLEANUP

