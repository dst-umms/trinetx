#!/usr/bin/env perl
#vim: syntax=perl tabstop=2 expandtab

#-------------------------------------
# @author: Mahesh Vangala
# @email: "<vangalamaheshh@gmail.com>"
# @date: "July, 10, 2017"
#-------------------------------------

my $in_file = $ARGV[0];

print_info($in_file);
exit $?;

sub print_info {
  my($file) = @_;
  open(FH, "$file") or die "Error in opening the file, $file, $!\n";
  my $header = <FH>;
  @$header = qw(Patient_ID Provider_ID Variant_Code_System Test_Date Sample_Site Gene_Symbol Gene_Name Ref_seq_id Wildtype Protein_Seq_Variant nucleotide_variant variant_db_name variant_id);
  print STDOUT join("\t", @$header), "\n";
  while(my $line = <FH>) {
    chomp $line;
    my($patient_id, $provider_id, $var_sys, $test_date, $sample_site, $gene_symbol,
      $gene_name, $wt, $p_var, $g_var, $id, $cancer_type) = split("\t", $line);
    print STDOUT join("\t", ($patient_id, $provider_id, $var_sys, $test_date, $sample_site, $gene_symbol,
        $gene_name, undef, $wt, $p_var, $g_var, undef, undef)), "\n";
  }
  close FH or die "Error in closing the file, $file, $!\n";
}

