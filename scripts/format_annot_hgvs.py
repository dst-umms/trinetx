#!/usr/bin/env python
#vim: syntax=python tabstop=2 expandtab

__author__ = "Mahesh Vangala"
__email__ = "<vangalamaheshh@gmail.com>"
__date__ = "Apr 10, 2017"
__doc__ = """
  Print Variant Annotation into CSV

  Just a formatting script
"""

import pandas as pd
import numpy as np
import sys

def formatDB(dbTemp):
  db = pd.DataFrame()
  db[["id", "nuc_change"]] = dbTemp[["query", "_id"]][dbTemp["notfound"] != True]
  #db[["aa_change", "gene_id", "gene_name"]] = 
  x = [getInfo(elem) for elem in dbTemp["snpeff.ann"][dbTemp["notfound"] != True]]
  db2 = pd.DataFrame(x, columns = ["aa_change", "gene_id", "gene_name"])
  return db.join(db2)

def getInfo(info):
  try:
    info = eval(info)
  except TypeError:
    return ['-', '-', '-']
  aa_change = {elem['hgvs_p'] for elem in info if "hgvs_p" in elem}
  gene_id = {elem['gene_id'] for elem in info if "gene_id" in elem}
  gene_name = {elem['gene_name'] for elem in info if "gene_name" in elem}
  aa_change = aa_change or ['-']
  gene_id = gene_id or ['-']
  gene_name = gene_name or ['-']
  myList = [";".join(aa_change), ";".join(gene_id), ";".join(gene_name)]
  return myList

if __name__ == "__main__":
  db = pd.read_csv(sys.argv[1], sep = ",", header = 0)
  db = formatDB(db)
  db.to_csv(sys.argv[2], header = True, index = False)
