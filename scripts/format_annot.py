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
  db["aa_change"] = [formatAminoChange(dbTemp["dbnsfp.aa.ref"][index], dbTemp["dbnsfp.aa.alt"][index], dbTemp["dbnsfp.aa.pos"][index]) \
                      if pd.notnull(dbTemp["dbnsfp.aa.ref"][index]) else getAminoChange(dbTemp["dbnsfp.aa"][index]) \
                      for index in dbTemp[dbTemp["notfound"] != True].index]
  db["gene"] = [dbTemp["clinvar.gene.symbol"][index] if pd.notnull(dbTemp["clinvar.gene.symbol"][index]) \
                else '-' for index in dbTemp[dbTemp["notfound"] != True].index]
  db["desc"] = [dbTemp["dbnsfp.clinvar.trait"][index] if pd.notnull(dbTemp["dbnsfp.clinvar.trait"][index]) \
                else '-' for index in dbTemp[dbTemp["notfound"] != True].index]
  return db

def formatAminoChange(ref, alt, pos):
  pos = eval(pos)
  if isinstance(pos, int):
    return 'p.' + ref + str(pos) + alt
  else:
    vals = ['p.' + ref + str(curPos) + alt 
          for curPos in sorted({int(x) for x in pos})] 
    return ";".join(vals)

def getAminoChange(val):
  try:
    val = eval(val)
  except NameError:
    return "-"
  except TypeError:
    return "-"
  vals = []
  for elem in val:
    if all(k in elem for k in ["ref", "alt", "pos"]):
      if isinstance(elem["pos"], int):
        vals.append('p.' + elem["ref"] + str(elem["pos"]) + elem["alt"])
      else:
        vals.extend(['p.' + elem["ref"] + str(sortedCurPos) + elem["alt"] for sortedCurPos in 
          sorted({int(curPos) for curPos in elem["pos"]})])
      
  return ";".join(vals)

if __name__ == "__main__":
  db = pd.read_csv(sys.argv[1], sep = ",", header = 0)
  db = formatDB(db)
  db.to_csv(sys.argv[2], header = True, index = False)
