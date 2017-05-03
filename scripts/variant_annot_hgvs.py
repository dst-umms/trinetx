#!/usr/bin/env python
#vim: syntax=python tabstop=2 expandtab

__author__ = "Mahesh Vangala"
__email__ = "<vangalamaheshh@gmail.com>"
__date__ = "May, 3, 2017"
__doc__ = """
  Fetch variant annotation information 

  For every provided COSMIC and dbSNP RS IDs, fetch
  corresponding annotation information such as
  cDNA change, aa change etc. that are of HGNC supported
  from snpEFF db.
"""

import sys
import pandas
import myvariant

def getSNPannot(ids):
  mv = myvariant.MyVariantInfo()
  df = mv.querymany(ids, scopes = 'cosmic.cosmic_id, dbsnp.rsid', 
        fields = '_id, snpeff.ann', as_dataframe = True)
  return df

def getIDs():
  ids = set() # order is not maintained 
              #efficient way to remove duplicates
  for id in sys.stdin:
    ids.add(id.strip())
  
  return list(ids)
    

if __name__ == "__main__":
  ids = getIDs() #returns a list of ids
  df = getSNPannot(ids)
  df.to_csv(sys.argv[1])
