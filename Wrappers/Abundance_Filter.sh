#!/bin/bash

# if zipped data is provided
if [ "$1" == "zip" ]
then

	# set temp zip output file
	temp_zip=$(mktemp -u XXXXXX.zip)

	IFS=$'\n'
	# for each file in the provided zip file
	for file in $(zipinfo -1 "$2")
	do
		IFS=$' \t\n'
		header=$(unzip -p "$2" "$file"| head -n 1 | grep -o "^.")
		if [ $header  == ">" ] || [ $header == "@" ]
		then
			# unzip the reads to the temp file
			unzip -p "$2" "$file" > "$file"

			# set the output path
			filtered="${file%.fast?}_filtered"

			# set the output format
			if [ $header == ">" ]
			then
				format=".fasta"
			else
				format=".fastq"
			fi

			# Run the abundance filter
			Abundance_Filter -f "$file" -m "$5" ${4} > "${filtered}${format}"

			# Check if the output file contains reads
			if [ -s "${filtered}${format}" ]
			then
				# ZIP the results and remove the redundant files
				zip -q -9 "$temp_zip" "${filtered}${format}"
			fi
			rm "${filtered}${format}" "$file"
		fi
	done
	# move the temp zip file to the galaxy output path
	mv "$temp_zip" "$3"

else
	Abundance_Filter -f "$2" -m "$5" ${4} > "$3"
fi
