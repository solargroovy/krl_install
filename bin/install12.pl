#!/usr/bin/perl
# Config script for kns_config.yml

use lib qw(
  /web/lib/perl
  ./perl
  );

use IO::File;
use Data::Dumper;
use Carp;
use HTML::Template;
use ConfMaker qw( :all );


use Kynetx::Configure;

my $config_file = "../files/kns_config.tmpl";
my $param_file = "../files/config.conf";
my $master = "/web/etc/kns_config.yml";
my $questions = read_section($param_file);
#print Dumper($questions);
my $template = HTML::Template->new(filename => $config_file);

my @params = $template->param();

foreach my $p (@params) {
  my $val;
  my $var = $template->query(name => $p);
  if ($var eq "LOOP") {
    my @list = $template->query(loop => $p);
    foreach my $loop_element (@list) {
      $val = q_array($loop_element, $questions->{uc($loop_element)});
    }
    $template->param(uc($p) => $val);
  } else {
      $val = q_single($questions->{uc($p)});
      $template->param($p => $val);
  }
}

rotate_file($master,$template->output());

# Build the Javascript RTE and Apache conf

# load the config variables from the file you just made
#

Kynetx::Configure::configure();

my $bin_dir = Kynetx::Configure::get_config("KOBJ_ROOT");
my $cmd = $bin_dir . '/bin/install-init-files.pl';
my $result = `$cmd`;

print $result, "\n";

$cmd = $bin_dir . '/bin/install-httpd-conf.pl -aljkf';

$result = `$cmd`;

print $result, "\n";
