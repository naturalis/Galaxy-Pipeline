#!/bin/bash

wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz

mkdir temp

tar -xzvf taxdump.tar.gz -C temp/

/home/galaxy/Tools/GetUpdate/ReFormat_TaxDump.py temp/names.dmp taxonid_names.tsv

rm temp/*
rm taxdump.tar.gz
rmdir temp

mv taxonid_names.tsv /home/galaxy/Extra_Ref/
