#!/bin/bash

# Create temp zip file
temp_zip=$(mktemp -u XXXXXX.zip)

# Create the BLAST database
makeblastdb -dbtype nucl -in "$1" > /dev/null 2>&1

# zip the results
zip -9 -q "$temp_zip" "$1".* > /dev/null 2>&1

# move the temp_zip file to the output file
mv "$temp_zip" "$2"

# remove the redundant files
rm "$1".*
