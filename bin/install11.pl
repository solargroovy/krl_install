#!/usr/bin/perl
# Generate the Logging config .og.conf

use lib qw(
  /web/lib/perl
  ./perl
  );

use IO::File;
use Data::Dumper;
use Carp;
use HTML::Template;
use ConfMaker qw( :all );

my $config_file = "../files/log.tmpl";
my $master = "/web/etc/log.conf";
my $default = "/web/logs";
my $template = HTML::Template->new(filename => $config_file);

my $log_dir = q_single({ 'desc' => 'Log directory',
      'default' => $default});
$template->param('LOG_DIR' => $log_dir);

rotate_file($master,$template->output());

