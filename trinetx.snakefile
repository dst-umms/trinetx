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
    inputCSV = "{sample}.csv"
  output:
    cosmicIDs = "analysis/annotation/cosmic.ids.txt"
  shell:
    # 35 - COSMIC ID
    "cut -f 35 -d \",\" {input.inputCSV} | grep -i cosm 1>{output.cosmicIDs} "

rule fetch_rs_ids:
  input:
    inputCSV = "{sample}.csv"
  output:
    rsIDs = "analysis/annotation/rs.ids.txt"
  shell:
    # 36 - Db_snp #also called rsid
    "cut -f 36 -d \",\" {input.inputCSV} | grep -i rs 1>{output.rsIDs} "


