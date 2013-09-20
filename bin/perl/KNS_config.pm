package ConfMaker.pm
# file: bin/perl/ConfMaker.pm
# This file is part of the Kinetic Rules Engine (KRE) Install Scripts
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

use strict;
#use warnings;
no warnings 'all';

use lib qw (
  /web/lib/perl
);

use File::Slurp;
use IO::File;

use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

our $VERSION     = 1.00;
our @ISA         = qw(Exporter);

# put exported names inside the "qw"

our %EXPORT_TAGS = (all => [
  qw(
    ask
    q_single
    q_array
    read_section
    write_section
  )]);
our @EXPORT_OK   =(@{ $EXPORT_TAGS{'all'} }) ;

use constant SEP => ",";


sub read_section {
  my ($file) = @_;
  my $tag;
  my @questions = ();
  my $fh = IO::File->new();
  while <$fh> {
    my $line = $_;
    chop $line;
    if ($line =~ /^#/) {
      $tag = $line;
    }
    my @params = split(SEP,$line);
    push(@questions,\@params);
  }
  return ($tag,\@questions);
}

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

sub write_section {
  my ($file,$tag,$description,$lines) = @_;
  my @old = read_file($file);
  my @new = ();
  my $prune = 0;
  my $found = 0;
  foreach my $line (@old) {
    push(@new,$line) unless ($prune);
    if ($line =~ m/^$tag/) {
      print "Replace section $tag\n";
      $prune = 1;
      $found = 1;
      foreach my $newline (@{$lines}) {
        push(@new,$newline);
      }
    } elsif ($line =~ m/^#/) {
      $prune = 0;
      push(@new,"\n");
      push(@new, $tag);
      push(@new,$line);
    }
  }
  if (! $found) {
    print "Append section $tag\n";
    my $eof = pop(@new);
    foreach my $newline (@{$lines}) {
      push(@new,$newline);
    }
    push(@new,$eof);
  }
  write_file($file,@new);
}
