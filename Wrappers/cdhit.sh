#!/bin/bash

# replace spaces with underscores in the fasta headres, since these
# might cause problems with scripts downstream (cdhit filtering and blasting)
sed -i 's/ /_/g' $1

# run the cdhit-est tool with the provided arguments
cdhit-est -i "$1" -o "$2" -c "$3" -T 0 -g 1 -d 0 > /dev/null 2>&1

# move the .clstr output file to the provided galaxy path
mv $2".clstr" $4

# replace the spaces in the cluster output fasta file, for the same reason
# as mentioned above
sed -i 's/>Cluster />Cluster_/g' $4

# get a tsv file containing the number of cluster + cluster sizes
# based on the .clstr information
grep -B 1 "^>" $4 | grep "^[^>-]" > $4".tsv"
tail -1 $4 >> $4".tsv"

# use the R script to create a histogram of the cluster sizes
CDHit_Hist $4".tsv" $5".png"  > /dev/null 2>&1

# remove the tsv file and send the histogram to galaxy
rm $4".tsv"
mv $5".png" $5
