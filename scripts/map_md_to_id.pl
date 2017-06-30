#!/usr/bin/env perl
#vim: syntax=perl tabstop=2 expandtab

#---------------------------
# @author: Mahesh Vangala
# @email: "<vangalamaheshh@gmail.com>"
# @date: June, 30, 2017
#---------------------------

use strict;
use warnings;
use Getopt::Long;

#------------------#
#     GLOBALS      #
#------------------#
my $DB_HEADER = undef;
#------------------#

my $options = parse_options();
my $id_info = get_info($$options{'id_file'}, 0);
my $db_info = get_info($$options{'db_file'}, 1);
print_info($id_info, $db_info);
#print_log($id_info, $$options{'prefix'} . '.id.log');
#print_log($db_info, $$options{'prefix'} . '.db.log');
exit $?;

sub parse_options {
  my $options = {};
  GetOptions($options, 'db_file|d=s', 'id_file|i=s', 'prefix|p=s', 'help|h');
  unless($$options{'db_file'} and $$options{'id_file'} and $$options{'prefix'}) {
    my $usage = "$0 <--db_file|-d> <--id_file|-i> <--prefix|-p> [--help|-h]";
    print STDERR $usage, "\n";
    exit 1;
  }
  return $options;
}


sub get_info {
  my($file, $flag) = @_;
  my $info = {};
  open(FH, "<$file") or die "Error in opening the file, $file, $!\n";
  if($flag) { $DB_HEADER = <FH>; } else {  my $id_header = <FH>; }
  while(my $line = <FH>) {
    chomp $line;
    my($md, $rest) = (undef, undef);
    if(not $flag) {
      my($md_temp, $id) = ($line =~ /(.+?),.+\".+\",(.+?),/);
      ($md, $rest) = ($md_temp, $id);
    } else {
      my($md_temp, @values) = split(",", $line);
      ($md, $rest) = ($md_temp, join(",",@values));
    }
    $$info{$md}{'seen'} = 0;
    push @{$$info{$md}{'info'}}, $rest;       
  }
  close FH or die "Error in closing the file, $file, $!\n";
  return $info;
}

sub print_info {
  my($id, $db) = @_;
  print STDOUT $DB_HEADER;
  foreach my $md(keys %$db) {
    my $md_formatted = undef;
    if($md =~ /^(\d\d)[\:\-]+(\S+)/) {
      $md_formatted = $1 . ':' . $2;
    } elsif($md =~ /(\D\D)(\d\d)[\:\-]+(\d+)/) {
      $md_formatted = $2 . ':' . $1 . sprintf("%06d", $3);
    } else {
      print STDERR "INFO: $md\n";
    }
    if($md_formatted and exists $$id{$md_formatted}) {
      $$id{$md_formatted}{'seen'} = 1;
      $$db{$md}{'seen'} = 1;
      foreach my $line(@{$$db{$md}{'info'}}) {
        print STDOUT ${$$id{$md_formatted}{'info'}}[0], ",", $line, "\n";
      }     
    }
  } 
}
