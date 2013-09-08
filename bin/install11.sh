#!/usr/bin/perl
# Config script for kns_config.yml

use IO::File;
use Data::Dumper;
use Carp;
use HTML::Template;


use constant SEP => ",";

my @questions = ();
my $q_file = "../files/config.conf";
my $templatef = "../files/kns_config.tmpl";

my $q_fh = IO::File->new();
if ($q_fh->open("< $q_file")) {
  while (<$q_fh>) {
    my $line = $_;
    chop $line;
    my @p = split(SEP,$line);
    push(@questions, \@p);
  }
} else {
  croak "Missing ($q_file) config parameters";
}

my $p;

my $template = HTML::Template->new(filename => $templatef);

foreach my $q (@questions) {
  my ($var,$ans) = ask($q);
  $p->{$var} = $ans;
}
print Dumper($p);

$template->param($p);

print $template->output;

sub ask {
  my ($q) = @_;
  my ($type,$desc,$var,$def) = @{$q};
  my $ans;
  if (defined $type && $type ne "") {
    $ans = q_array($desc,$var,$def);
    return ($type, $ans);
  } else {
    return ($var, q_single($desc,$var,$def));
  }
}

sub q_single {
  my ($desc,$var,$def) = @_;
  print "$desc: ($def) ";
  my $temp = <STDIN>;
  chop $temp;
  if ($temp) {
    return $temp 
  } else {
    return $def
  }
}

sub q_array {
  my ($desc,$var,$def) = @_;
  print "$desc: <press ENTER to quit>\n";
  print "($def) ";
  my $input;
  my @array = ();
  do {
    $input = <STDIN>;
    chop $input;
    if ($input) {
      push(@array,{$var => $input});
    }
  } until ($input eq  "");
  if (scalar @array == 0) {
    push (@array,{ $var => $def});
  } 
  return \@array;
}
