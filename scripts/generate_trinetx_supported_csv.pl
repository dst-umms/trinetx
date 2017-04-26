#!/usr/bin/env perl
#vim: syntax=perl tabstop=2 expandtab
#
#-------------------------
# @author: "Mahesh Vangala"
# @email: "<vangalamaheshh@gmail.com>"
# @date: "Apr, 26, 2017"
#-------------------------

use strict;
use warnings;

my $csv_info_file = $ARGV[0];
my $variant_db_file = $ARGV[1];

my $variant_db_info = get_db_info($variant_db_file);
process_data($csv_info_file, $variant_db_info);
exit $?;

sub get_db_info {
  my($file) = @_;
  my $info = {};
  open(FH, "<$file") or die "Error opening the file, $file, $!\n";
  my $header = <FH>;
  while(my $line = <FH>) {
    chomp $line;
    my @array = split(",", $line);
    $$info{$array[0]} = $line;
  }
  close FH or die "Error in clsoing the file, $file, $!\n";
  return $info;
}

sub process_data {
  my($file, $db) = @_;
  open(FH, "<$file") or die "Error in openign the file, $file, $!\n";
  my $header = <FH>;
  $header = ["Patient ID", "Provider ID", "Variant Code System", 
              "Test Date", "Sample Site", "Gene Symbol",
              "Gene Name", "Wildtype", "Protein Sequence Variant",
              "Genomic DNA Sequence Variant"];
  print STDOUT join(",", @$header), "\n";
  while(my $line = <FH>) {
    chomp $line;
    my($patient_id, $cancer_type) = ($line =~ /^(\d+),(.+?),/);
    my($cosm) = ($line =~ /(COSM\d+)/);
    my($rs) = ($line =~ /(rs\d+)/);
    my $defaults = {
                    $$header[1] => "UMass Memorial", 
                    $$header[2] => "HGVS",
                    $$header[3] => "20170131",
                    $$header[7] => "F"
                    };
    my $info = undef;
    if($cosm or $rs) {
      if($cosm and exists $$db{$cosm}) {
        $info = process_info($$db{$cosm});
      }
      elsif($rs and exists $$db{$rs}) {
        $info = process_info($$db{$rs});
      }
    }
    if($info) {
      foreach my $aa(@{$$info[2]}) {
        print STDOUT join(",", (
          $patient_id, $$defaults{$$header[1]}, $$defaults{$$header[2]}, 
          $$defaults{$$header[3]}, $cancer_type, $$info[0], $$info[0], 
          $$defaults{$$header[7]}, $aa, $$info[1] 
        )), "\n";
      }
    }
  }
  close FH or die "Error in closing the file, $file, $!\n";
}

sub process_info {
  my($line) = @_;
  my $info = undef;
  my($id, $nuc_change, $aa_change, $gene, $desc) = split(",", $line);
  if($gene eq "-" or $nuc_change eq "-" or $aa_change eq "-") {
    print STDERR "WARN: '$line' is being ignored due to lack of required info.\n";
  }
  else {
    my @aa_info = split(";", $aa_change);
    $info = [$gene, $nuc_change, \@aa_info];
  } 
  return $info;   
}
