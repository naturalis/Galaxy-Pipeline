#!/bin/bash

# if the input data is located in a zip file:
if [ "$1" == "zip" ]
then
	# Set read headers
	if [ "$2" == "-fastq" ]; then
		header="@"
	else
		header=">"
	fi

	# Set output extension
	ext=".fastq"
	if [ "$3" == "1" ]; then
		ext=".fasta"
	fi

	# set temp zip output file
	temp_zip=$(mktemp -u XXXXXX.zip)

	# go through the files in the zip
	IFS=$'\n'
	for file in $(zipinfo -1 "$4")
	do
		IFS=$' \t\n'
		# check if the zipped file matches the selected header
		if [ $(unzip -p "$4" "$file" | head -n 1 | grep -o "^.") == "$header" ]
		then
			# set temp file for the reads
			temp=$(mktemp)

			# unzip the reads to the temp file, remove the temp file without the extension afterwards
			unzip -p "$4" "$file" | prinseq-lite "$2" stdin -out_format "$3" -out_good "$temp" "${@:6}" > /dev/null 2>&1
			rm "$temp"

			# Check if the output file contains reads; if so rename the file (mv) and add it to the temp zip
			# if it doesn't contain sequences remove it.
			if [ -s "$temp$ext" ]; then
				filtered="${file%.*}_filtered$ext"
				mv "$temp$ext" "$filtered"
				zip -q -9 "$temp_zip" "$filtered"
				rm "$filtered"
			fi
		fi
	done
	# mv the temp zip file to the definite output file
	if [ -s "$temp_zip" ]; then
		mv "$temp_zip" "$5"
	else
		rm "$temp_zip"
	fi
# if a normal sequence file is provided
else
	# run the prinseq lite tool with the user input
	prinseq-lite "$2" "$4" -out_format "$3" -out_good "$5" "${@:6}" > /dev/null 2>&1
	# if there is an output file (i.e. not all reads have been filtered out)
	# move the output file to the galaxy path
	if [ -f "${5}".* ]; then
		mv "${5}".* "$5"
	fi
fi
