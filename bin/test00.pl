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

use ConfMaker qw( :all );
my $logger = get_logger();
my $num_tests = 0;

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
my ($password);
$my_req_info = Kynetx::Test::gen_req_info($rid);
$rule_env = Kynetx::Test::gen_rule_env();
$rid = "initial_setup";
$rule_name = "foo";
$r = Kynetx::Test::configure();
$session = Kynetx::Test::gen_session($r,$rid);

$username =  $DICTIONARY[rand(@DICTIONARY)];
chomp($username);

$password =  $DICTIONARY[rand(@DICTIONARY)];
chomp($password);
##############################################################
# 
# MongoDB connection test
#
##############################################################

my $mdb = Kynetx::MongoDB::get_mongo();
@results = $mdb->collection_names();

#$logger->debug("Collections: ", sub {Dumper(@results)});

my @list = ConfMaker::collections_from_config();

$description = "Compare collections from script with mongo";
cmp_deeply(\@list,subbagof(@results),$description);
$num_tests++;

############################################################
#
# PCI 
#
#############################################################
use Kynetx::Modules::PCI;
use Kynetx::Persistence::KPDS qw(:all);

$description = "Create a temporary key";
my $system_key = Kynetx::Modules::PCI::create_system_key();
isnt($system_key,undef,$description);
$num_tests++;


$description= "Check system key";
$result = Kynetx::Modules::PCI::check_system_key($system_key);
is($result,1,$description);
$num_tests++;

$description = "Make sure key works for PCI module";
my $keys = {'root' => $system_key};
($js, $rule_env) = Kynetx::Keys::insert_key(
  $my_req_info,
  $rule_env,
  'system_credentials',
  $keys);

$result = Kynetx::Modules::PCI::pci_authorized($my_req_info,$rule_env,$session,$rule_name,"foo",[]);
is($result,1,$description);
$num_tests++;

$description = "Use the system key to create a developer key";
$result = Kynetx::Modules::PCI::developer_key($my_req_info,$rule_env,$session,$rule_name,"foo",[]);
isnt($result, undef, $description);
$num_tests++;

$description = "Create a test user";
my $temp_ken = Kynetx::Test::gen_user($my_req_info,$rule_env,$session,$username);
isnt($temp_ken,undef,$description);
$num_tests++;

$description="Verify account created";
$args = $username;
$result = Kynetx::Modules::PCI::check_username($my_req_info,$rule_env,$session,$rule_name,"foo",[$args]);
is($result,1,$description);
$num_tests++;

$description="Set the account password";
$args=[{'username' => $username},$password];
$result = Kynetx::Modules::PCI::reset_account_password($my_req_info,$rule_env,$session,$rule_name,"foo",$args);
is($result,1,$description);
$num_tests++;

$description="Verify account password";
$args=[$username,$password];
$expected = { 'nid' => re(qr/\d+/)};
$result = Kynetx::Modules::PCI::account_authorized($my_req_info,$rule_env,$session,$rule_name,"foo",$args);
cmp_deeply($result,$expected,$description);
$num_tests++;


$description="Reject bad account password";
$args=[$username,"wertyq"];
$result = Kynetx::Modules::PCI::account_authorized($my_req_info,$rule_env,$session,$rule_name,"foo",$args);
is($result,0,$description);
$num_tests++;


###################################################################
#
# Tokens
#
##################################################################
use Kynetx::Persistence::KToken;

$description = "Get the primary ECI for this KEN";
my $d_token = Kynetx::Persistence::KToken::get_default_token($temp_ken);
isnt($d_token,undef,$description);
$num_tests++;

$logger->debug("Default token: $d_token");

###################################################################
#
# CLEANUP
#
# #################################################################

Kynetx::Test::flush_test_user($temp_ken,$username);
done_testing($num_tests);
