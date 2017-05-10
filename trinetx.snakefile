#!/usr/bin/env python
#vim: syntax=python tabstop=2 expandtab

__author__ = "Mahesh Vangala"
__email__ = "<vangalamaheshh@gmail.com>"
__date__ = "Apr, 25, 2017"

"""
  TrinetX pipeline

  1) Full CSV -> Subset CSV
  2) Fetch COSMIC, RS IDs
  3) Fetch annotation info for IDs
  4) Generate formatted output CSV
"""

configfile: "trinetx/trinetx.params.yaml"

rule target:
  input:
    "analysis/trinetx/{sample}.clinvar.csv".format(sample = config["sample"]),
    "analysis/trinetx/{sample}.hgvs.csv".format(sample = config["sample"])

rule subset_csv:
  input:
    inputCSV = "{sample}.csv"
  output:
    outputCSV = "analysis/input/{sample}.filtered.csv",
    inputCSV = "analysis/input/{sample}.original.csv"
  shell:
    # 1 - UniqueIdentifier, 2 - Cancer Type, 24 - CHROMOSOME,
    # 25 - CHROMOSOME POSITION, 26 - GENE SYMBOL, 33 - MUTATION CALL, 
    # 34 - AMINO ACID  CHANGE, 35 - COSMIC ID, 36 - Db_snp
    "cut -f 1,2,24,25,26,33,34,35,36 -d \",\" {input.inputCSV} 1>{output.outputCSV} "
    "&& cp {input.inputCSV} {output.inputCSV} "

rule fetch_cosmic_ids:
  input:
    inputCSV = "{sample}.csv".format(sample = config["sample"])
  output:
    cosmicIDs = "analysis/annotation/{sample}.cosmic.ids.txt"
  shell:
    # 35 - COSMIC ID
    "cut -f 35 -d \",\" {input.inputCSV} | grep -i cosm 1>{output.cosmicIDs} "

rule fetch_rs_ids:
  input:
    inputCSV = "{sample}.csv".format(sample = config["sample"])
  output:
    rsIDs = "analysis/annotation/{sample}.rs.ids.txt"
  shell:
    # 36 - Db_snp #also called rsid
    "cut -f 36 -d \",\" {input.inputCSV} | grep -i rs 1>{output.rsIDs} "

rule fetch_variant_annotation:
  input:
    cosmicIDs = "analysis/annotation/{sample}.cosmic.ids.txt".format(sample = config["sample"]),
    rsIDs = "analysis/annotation/{sample}.rs.ids.txt".format(sample = config["sample"])
  output:
    annotFile = "analysis/annotation/{sample}.clinvar_variants.csv"
  shell:
    "cat {input.cosmicIDs} {input.rsIDs} | "
    "python trinetx/scripts/variant_annot.py {output.annotFile} "


rule format_variant_annotation:
  input:
    annotFile = "analysis/annotation/{sample}.clinvar_variants.csv".format(sample = config["sample"])
  output:
    formattedFile = "analysis/annotation/{sample}.clinvar_variants.format.csv"
  shell:
    "python trinetx/scripts/format_annot.py {input.annotFile} {output.formattedFile} "


rule trinetx_csv:
  input:
    formattedAnnotFile = "analysis/annotation/{sample}.clinvar_variants.format.csv".format(sample = config["sample"]),
    filteredCSV = "analysis/input/{sample}.filtered.csv".format(sample = config["sample"]),
    gene_sym2name = "trinetx/static/gene_sym2name.csv"
  output:
    trinetxCSV = "analysis/trinetx/{sample}.clinvar.csv",
    trinetxLog = "analysis/trinetx/{sample}.clinvar.log"
  shell:
    "perl trinetx/scripts/generate_trinetx_supported_csv.pl "
    "{input.filteredCSV} {input.formattedAnnotFile} {input.gene_sym2name} "
    "1>{output.trinetxCSV} 2>{output.trinetxLog} "

rule generate_hgvs_annotation:
  input:
    cosmicIDs = "analysis/annotation/{sample}.cosmic.ids.txt".format(sample = config["sample"]),
    rsIDs = "analysis/annotation/{sample}.rs.ids.txt".format(sample = config["sample"])
  output:
    annotFile = "analysis/annotation/{sample}.hgvs_variants.csv"
  shell:
    "cat {input.cosmicIDs} {input.rsIDs} | "
    "python trinetx/scripts/variant_annot_hgvs.py {output.annotFile} "

rule format_hgvs_annotation:
  input:
    hgvsFile = "analysis/annotation/{sample}.hgvs_variants.csv".format(sample = config["sample"])
  output:
    formattedHgvsFile = "analysis/annotation/{sample}.hgvs_variants.format.csv"
  shell:
    "python trinetx/scripts/format_annot_hgvs.py {input.hgvsFile} {output.formattedHgvsFile} "

rule hgvs_csv:
  input:
    formattedHgvsFile = "analysis/annotation/{sample}.hgvs_variants.format.csv".format(sample = config["sample"]),
    filteredCSV = "analysis/input/{sample}.filtered.csv".format(sample = config["sample"]),
    gene_sym2name = "trinetx/static/gene_sym2name.csv"
  output:
    hgvsCSV = "analysis/trinetx/{sample}.hgvs.csv",
    hgvsLog = "analysis/trinetx/{sample}.hgvs.log"
  shell:
    "perl trinetx/scripts/generate_trinetx_supported_csv.pl "
    "{input.filteredCSV} {input.formattedHgvsFile} {input.gene_sym2name} "
    "1>{output.hgvsCSV} 2>{output.hgvsLog} "
