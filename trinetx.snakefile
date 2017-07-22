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
    # 1 - UniqueIdentifier, 7 - Cancer Type, 31 - CHROMOSOME,
    # 32 - CHROMOSOME POSITION, 33 - GENE SYMBOL, 40 - MUTATION CALL, 
    # 41 - AMINO ACID  CHANGE, 42 - COSMIC ID, 43 - Db_snp
    "cut -f 1,7,31,32,33,40,41,42,43 -d \",\" {input.inputCSV} 1>{output.outputCSV} "
    "&& cp {input.inputCSV} {output.inputCSV} "

rule fetch_cosmic_ids:
  input:
    inputCSV = "{sample}.csv".format(sample = config["sample"])
  output:
    cosmicIDs = "analysis/annotation/{sample}.cosmic.ids.txt"
  shell:
    # 42 - COSMIC ID
    "cut -f 42 -d \",\" {input.inputCSV} | grep -i cosm 1>{output.cosmicIDs} "

rule fetch_rs_ids:
  input:
    inputCSV = "{sample}.csv".format(sample = config["sample"])
  output:
    rsIDs = "analysis/annotation/{sample}.rs.ids.txt"
  shell:
    # 43 - Db_snp #also called rsid
    "cut -f 43 -d \",\" {input.inputCSV} | grep -i rs 1>{output.rsIDs} "

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

rule final_formatted_file:
  input:
    in_csv = "analysis/trinetx/{sample}.clinvar.csv".format(sample = config["sample"])
  output:
    out_csv = "UMass_Genomics.csv"
  shell:
    "perl trinetx/scripts/final_file.pl "
    "{input.in_csv} 1>{output.out_csv} "

rule generate_report:
  input:
    image_file = "data.png"
  output:
    "UMass_TriNetX_Genomics_Report.html"
  run:
    from snakemake.utils import report
    from snakemake.report import data_uri
    sphinx_str = """
================================
UMass TrinetX Genomics Overview:
================================

Background: 
===========

Data Sciences & Technology (DST), IT, provides and supports patient cohort exploration using Genomics data in addition to clinical data. DST in collaboration with Molecular Diagnostic Laboratories at UMass Memorial Hospital, gathered and curated precision medicine data from patients since 2014 and is provided to medical researchers for research purposes.

This document describes the overall counts of patients with variant information at gene level. 

NOTE: Out of 1174 unique MRNs collected from Mol Dx lab, 157 MRNs are not found in master MRN table collected from hospital.

Following plot represents patient counts at gene level with respect to TriNetX and Mol Dx annotation information. Since, TriNetX variant annotation look up is much more stringent, it is possible and most likely for some variants called by MolDx workflows not present in TriNetX and thus, TriNetX counts will always be either less than or equal to MolDx patient counts for each gene.

"""
    sphinx_str += "\n\t.. image:: " + data_uri(input.image_file) + "\n\n"
    report(sphinx_str, output[0], metadata="Data Sciences & Technology, UMMS", **{'Copyrights:':"trinetx/static/dst.png"})
