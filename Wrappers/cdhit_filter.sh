#!/bin/bash

# run the cd hit fileter tool with the provided arguments
# note: only works with non zip data
CD-HIT-Filter "${@:1:$(($#-1))}"
# move the output file to the provided output path
mv "${2%.*}"*min*.fasta $7

