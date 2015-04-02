#!/bin/bash

# if the provided file is in zip format
if [ "$1" == "zip" ]
then
	# set temp zip output file
	temp_zip=$(mktemp -u XXXXXX.zip)

	IFS=$'\n'
	# get all the tsv file from the zip
	for tsv in $(zipinfo -1 "$2" | grep tsv$)
	do
		IFS=$' \t\n'
		# unzip the blast to the temp file
		unzip -p "$2" "$tsv" > "$tsv"

		# set the path for expected .clstr file based on the tsv file
		clstr="${tsv%_clustered*}"_clustered.clstr

		# get the .clstr file from the cluster zip
		unzip -p "$3" "$clstr" > "$clstr"

		# run the Expand_BLAST tool for the tsv + clstr file
		Expand_BLAST -b "$tsv" -c "$clstr"

		# Zip the resulting expanded.tsv file to the temp zip
		zip -q -9 "$temp_zip" "${tsv%.*}"_expanded.tsv

		# remove the used files
		rm "$tsv" "$clstr" "${tsv%.*}"_expanded.tsv
	done
	# Move the temp zip file to the galaxy output path
	mv "$temp_zip" "$4"

# if non-zipped files are submitted
else
	# Run the Expand_BLAST tools for the provided tsv and clstr file
	Expand_BLAST -b "$2" -c "$3"
	# move the output file to the galaxy path
	mv "${2%.*}"_expanded.tsv "$4"
fi
