#!/usr/bin/env python

# This script downloads the uncultered and evironmental GIs from the nucleotide database

from Bio import Entrez

Entrez.email = "HTS-barcode-checker@gmail.com"
handle = Entrez.esearch(db="nucleotide", term="environmental samples[organism] OR metagenomes[orgn]", retmax=100000000)
record = Entrez.read(handle)

#print len(record["IdList"])


for GI in record["IdList"]:
	print GI
