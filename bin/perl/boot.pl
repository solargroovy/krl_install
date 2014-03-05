#!/usr/bin/perl

# Installs the bootstrap ruleset, system credentials module
# and site tag for KRE administration
#

# Change this location if your KRE is installed elsewhere
use utf8;
use lib qw( /web/lib/perl 
            ./perl
          );
use strict;

# Perl Modules
use Carp;
use LWP;
use Data::Dumper;
use HTTP::Request;
use HTML::Template;
use Cache::Memcached;

# KRE specific Modules
use Kynetx::Configure qw(:all);
use Kynetx::Modules::PCI;
use Kynetx::Persistence::Ruleset;
use Kynetx::Test;
use Kynetx::FakeReq;

# Install local modules
use ConfMaker qw(:all );

# Run as root
#
if ($> != 0) {
  croak "$0 must be run with root privileges";
}

my ($code,$msg) = check_engine();
if ($code == 200) {
  $msg =~ m/KNS build number (\w+)/;
  print STDOUT "KRE build $1\n";
} else {
  croak "Please start apache"
}

# Access to the kns_config.yml 
Kynetx::Configure::configure();

Kynetx::Memcached::init();
# Mongo
#Kynetx::MongoDB::init();

# Get salt 
my $salt = Kynetx::Configure::get_config("PCI_KEY");

croak "PCI_KEY not found, please configure your kns_config.yml" unless ($salt);

my $system_credential = Kynetx::Modules::PCI::create_system_key($salt);

my $cred_check = Kynetx::Modules::PCI::check_system_key($system_credential);

print "Cred valid: ",$cred_check,"\n";


print "Current Directory is " . Cwd::getcwd() . "\n";

my $cwd = ConfMaker::ask(["",{ 'desc' => "Template directory",'default' =>'../files/tmpl'},"dir",'../files/tmpl']);

# Templates
my $boot_template = "$cwd/system_bootstrap.tmpl";
my $key_template = "$cwd/system_credentials.tmpl";
my $html_template = "$cwd/system_index.tmpl";

my $templates = {
  'boot_template' => "$cwd/system_bootstrap.tmpl",
  'key_template' => "$cwd/system_credentials.tmpl",
  'html_template' => "$cwd/system_index.tmpl"

};

foreach my $t (keys %{$templates}) {
  my $fh = IO::File->new($templates->{$t});
  croak "Missing template $templates->{$t}" unless (-f $templates->{$t});
}

# Change these <string>.prod if you don't want to accept the defaults
my $bootstrap_rid = "systemBootstrap";
my $module_rid = "sysCredentials";



my $ruleset_owner = Kynetx::Configure::get_config("DEFAULT_RULESET_OWNER") ||
    +DEFAULT_OWNER_USERNAME; 
my $ken = Kynetx::Persistence::KEN::ken_lookup_by_username($ruleset_owner);
my $oeci = Kynetx::Persistence::KToken::get_default_token($ken);

croak "Default ruleset owner ($ruleset_owner) not defined" unless ($ken);

# Check if default ruleset is already defined
my $rid = $bootstrap_rid . '.prod';

my $rid_info = Kynetx::Persistence::Ruleset::get_ruleset_info($rid);
print Dumper $rid_info;

if ($rid_info) {
  print "\n", "Bootstrap ruleset already defined";
} else {
  my $uri = make_bootstrap_krl($bootstrap_rid,$module_rid,$templates->{"boot_template"});
  install_ruleset($bootstrap_rid,$uri);
  $uri = make_module_krl($module_rid,$system_credential,$bootstrap_rid,$templates->{"key_template"});
  install_ruleset($module_rid,$uri);
  make_index('b_index.html',$bootstrap_rid,$templates->{"html_template"});
}


####################
sub install_ruleset {
  my ($rid,$uri) = @_;
  my $rid_info = Kynetx::Persistence::Ruleset::get_ruleset_info($rid . '.prod', );
  if ($rid_info) {

  } else {
    my $ruleset_owner = Kynetx::Configure::get_config("DEFAULT_RULESET_OWNER");
    if ($ruleset_owner) {
      my $ken = Kynetx::Persistence::KEN::ken_lookup_by_username($ruleset_owner);
      if ($ken) {
        my $owner_eci = Kynetx::Persistence::KToken::get_oldest_token($ken);
        my $r = Kynetx::Test::configure();
        my $session = Kynetx::Test::gen_session($r,$rid);
        my $req_info = Kynetx::Test::gen_req_info($rid);
        my $rule_env = Kynetx::Test::gen_rule_env();
        my $root_env = Kynetx::Test::gen_root_env($req_info,$rule_env,$session);
        print "\n", "Installing $rid";
        my $args = [$rid];
        my $mods;
        my $vars;
        my $config = {
          'owner' => $owner_eci,
          'uri' => $uri
        };
        print "\n", Dumper $config;
        my $result = Kynetx::Modules::RSM::do_create($req_info,$root_env,$session,$config,$mods,$args,$vars);
        print "\n", "Result: ", Dumper $result;
        $args = [$rid . '.prod'];
        Kynetx::Modules::RSM::do_flush($req_info,$root_env,$session,$config,$mods,$args,$vars);
        my $status = Kynetx::Modules::RSM::do_validate($req_info,$root_env,$session,$config,$mods,$args,$vars);
        print "\n", "Validation: ", Dumper $status;
      } 
    }

  }
}

sub make_index {
  my ($fname,$rid,$template) = @_;
  my $krl = HTML::Template->new(filename => $template);
  $krl->param('BOOTSTRAP' => $rid);
  html_out($fname,$krl->output());
}

sub make_module_krl {
  my ($rid,$key,$boot_rid,$template) = @_;
  print "Using $template\n";
  my $krl = HTML::Template->new(filename => $template);
  $krl->param('CRED_RID' => $rid);
  $krl->param('ROOT_KEY' => $key);
  $krl->param('BOOTSTRAP' => $boot_rid);
  return krl_out($rid,$krl->output());
}


sub make_bootstrap_krl {
  my ($rid,$module,$template) = @_;
  my $krl = HTML::Template->new(filename => $template);
  $krl->param('CREDENTIALS_MODULE' => $module);
  $krl->param('RID' => $rid);
  return krl_out($rid,$krl->output());
          
}

sub html_out {
  my ($filename,$text) = @_;
  my $repo = Kynetx::Configure::get_config("RULE_REPOSITORY");
  my $h_repo = $repo . '../sitetags';
  my $cwd = ConfMaker::ask(["",{ 'desc' => "HTML directory",'default' =>$h_repo},"dir",$h_repo]);
  $filename = $cwd ."/$filename";
  my $fh = IO::File->new("> $filename");
  print $fh $text;
  undef $fh;
}

sub krl_out {
  my ($rid,$text) = @_;
  my $r_type = Kynetx::Configure::get_config("RULE_REPOSITORY_TYPE");
  my $repo = Kynetx::Configure::get_config("RULE_REPOSITORY");
  if ($r_type eq "file") {
    my $filename = $repo . $rid . '.krl';
    my $fh = IO::File->new("> $filename");
    print $fh $text;
    undef $fh;
    if ($filename =~ m/file:\/\//) {
      return $filename;
    } else {
      return 'file://' . $filename;
    }
  }
  return undef;
}


sub check_engine {
  my $ua = LWP::UserAgent->new;
  my $url = "http://127.0.0.1/manage/version/";
  my $req = HTTP::Request->new(GET => $url);
  my $response = $ua->request($req);
  my $code = $response->code();
  my $msg = $response->content();
  return ($code,$msg);
}
1;
