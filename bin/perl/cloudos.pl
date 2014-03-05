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
use YAML::XS;

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
#my $salt = Kynetx::Configure::get_config("PCI_KEY");

#croak "PCI_KEY not found, please configure your kns_config.yml" unless ($salt);

#my $system_credential = Kynetx::Modules::PCI::create_system_key($salt);

# Create just a temporary key
my $system_credential = Kynetx::Modules::PCI::create_system_key();
my $cred_check = Kynetx::Modules::PCI::check_system_key($system_credential);

print "Cred valid: ",$cred_check,"\n";


print "Current Directory is " . Cwd::getcwd() . "\n";

my $cwd = ConfMaker::ask(["",{ 'desc' => "Source directory",'default' =>'/web/src'},"dir",'/web/src']);



my $ruleset_owner = Kynetx::Configure::get_config("DEFAULT_RULESET_OWNER") ||
    +DEFAULT_OWNER_USERNAME; 
my $ken = Kynetx::Persistence::KEN::ken_lookup_by_username($ruleset_owner);
my $oeci = Kynetx::Persistence::KToken::get_default_token($ken);

croak "Default ruleset owner ($ruleset_owner) not defined" unless ($ken);

my $config_file = "../files/cloudos.yml";
my $config = read_config($config_file);

print Dumper($config);

my $rulesets = $config->{"rulesets"};
foreach my $rid (keys %{$rulesets}) {
  print "Configure $rid\n";
  my $template = $cwd . '/' . $rulesets->{$rid}->{"filename"};
  print "\t$template\n";
  my $text = make_krl($template,$rulesets->{$rid});
  my $filename = krl_out($rid,$text);
  print "Created : $filename\n";
}



####################
sub make_krl {
  my ($filename,$rconfig,$vars) = @_;
  my $vars = $rconfig->{'vars'};
  my $krl = HTML::Template->new(filename => $filename);
  set_common($krl);
  $krl->param('rid' => $rconfig->{'rid'});
  foreach my $var (keys %{$vars}){
    print "\t$var : " . $vars->{$var} . "\n";
    my ($desc,$default) = split(/\|/,$vars->{$var});
    my $value = ConfMaker::ask([
        "",
        {
          'desc' => $desc,
          'default' => $default
        },
        $var,
        $default
      ]);
    $krl->param($var => $value);
  }
  return $krl->output();
  
}

sub set_common {
  my ($template) = @_;
  my $common = $config->{'common'};
  my @pnames = $template->param();
  #print "params: " , join(",", @pnames);
  foreach my $key (@pnames) {   
    print "$key : ", $common->{uc($key)}, "\n";
    $template->param(uc($key) => $common->{uc($key)});    
  }

}

sub krl_out {
  my ($rid,$text) = @_;
  my $r_type = Kynetx::Configure::get_config("RULE_REPOSITORY_TYPE");
  my $repo = Kynetx::Configure::get_config("RULE_REPOSITORY");
  if ($r_type eq "file") {
    my $filename = $repo . $rid . '.krl';
    print "File: $filename\n";
    my $oldfile = ConfMaker::rotate_file($filename,$text);  
    my ($uid,$guid) = getuid();
    chown $uid,$guid, $filename;  
    if ($filename =~ m/file:\/\//) {
      return $filename;
    } else {
      return 'file://' . $filename;
    }
  }
  return undef;
}

sub getuid {
  my ($login,$pass,$uid,$gid) = getpwnam("web");
  return ($uid,$gid);
}

sub read_config {
  my ($filename) = @_;
  my $config;
  if ( -e $filename ) {
    $config = YAML::XS::LoadFile($filename) ||
      warn "Can't open configuration file $filename: $!";
  }
  return $config;
}

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
