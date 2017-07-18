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
my $gene_sym2name_file = $ARGV[2];

my $variant_db_info = get_db_info($variant_db_file);
my $gene_sym2name = get_gene_sym2name_info($gene_sym2name_file);
process_data($csv_info_file, $variant_db_info, $gene_sym2name);
exit $?;

sub get_gene_sym2name_info {
  my($file) = @_;
  my $info = {};
  open(FH, "<$file") or die "Error in opening the file, $file, $!\n";
  my $header = <FH>;
  while(my $line = <FH>) {
    chomp $line;
    my($sym, $name) = (undef, undef);
    if($line =~ /\"/) {
      my($cur_sym, $cur_status, $cur_name, $cur_id) = ($line =~ /(.+?),(.+?),\"(.+?)\",(.+)/);
#      $cur_name =~ s/,/;/g;
      ($sym, $name) = ($cur_sym, $cur_name);
    } else {
      my($cur_sym, $cur_status, $cur_name, $cur_id) = split(",", $line);
      ($sym, $name) = ($cur_sym, $cur_name);
    }
    $$info{$sym} = $name;
  }
  close FH or die "Error in closing the file, $file, $!\n";
  return $info;
}

sub get_db_info {
  my($file) = @_;
  my $info = {};
  open(FH, "<$file") or die "Error opening the file, $file, $!\n";
  my $header = <FH>;
  while(my $line = <FH>) {
    chomp $line;
    my @array = split(",", $line);
    $$info{$array[0]} = join("\t", @array);
  }
  close FH or die "Error in clsoing the file, $file, $!\n";
  return $info;
}

sub process_data {
  my($file, $db, $gene_info) = @_;
  open(FH, "<$file") or die "Error in openign the file, $file, $!\n";
  my $header = <FH>;
  $header = ["Patient ID", "Provider ID", "Variant Code System", 
              "Test Date", "Sample Site", "Gene Symbol",
              "Gene Name", "Wildtype", "Protein Sequence Variant",
              "Genomic DNA Sequence Variant", "(COSMIC/RS) ID", "Cancer Type"];
  print STDOUT join("\t", @$header), "\n";
  while(my $line = <FH>) {
    chomp $line;
    my($patient_id, $cancer_type) = ($line =~ /^(.*?),(.+?),/);
    print STDERR "WARN: '$line' is being ignored due to lack of patient id\n" and next if not $patient_id;
    my($cosm) = ($line =~ /(COSM\d+)/);
    my($rs) = ($line =~ /(rs\d+)/);
    my $defaults = {
                    $$header[1] => "UMass Memorial", 
                    $$header[2] => "HGVS",
                    $$header[3] => "20170131",
                    $$header[4] => "UNKNOWN",
                    $$header[7] => "F"
                    };
    my $info = undef;
    my $id = undef;
    if($cosm or $rs) {
      if($cosm and exists $$db{$cosm}) {
        $info = process_info($$db{$cosm});
        $id = $cosm;
      }
      elsif($rs and exists $$db{$rs}) {
        $info = process_info($$db{$rs});
        $id = $rs;
      }
    }
    if($info) {
      foreach my $aa(@{$$info[2]}) {
        print STDOUT join("\t", (
          $patient_id, $$defaults{$$header[1]}, $$defaults{$$header[2]}, 
          $$defaults{$$header[3]}, $$defaults{$$header[4]}, $$info[0], 
          $$gene_info{$$info[0]}, $$defaults{$$header[7]}, $aa, 
          $$info[1], $id, $cancer_type 
        )), "\n";
      }
    }
  }
  close FH or die "Error in closing the file, $file, $!\n";
}

sub process_info {
  my($line) = @_;
  my $info = undef;
  my($id, $nuc_change, $aa_change, $gene, $desc) = split("\t", $line);
  if($gene eq "-" or $nuc_change eq "-" or $aa_change eq "-") {
    print STDERR "WARN: '$line' is being ignored due to lack of required info.\n";
  }
  else {
    my @aa_info = split(";", $aa_change);
    my @gene_info = split(";", $gene);
    my( $nuc ) = ($nuc_change =~ /(g\..+)/);
    $info = [$gene_info[0], $nuc, \@aa_info];
  } 
  return $info;   
}
