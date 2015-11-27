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
		if [ $(unzip -p "$2" "$file" | head -n 1 | grep -o "^.") == ">" ]
		then
			# unzip the reads to the temp file and replace spaces in
			# the fasta header with underscores
			unzip -p "$2" "$file" | sed 's/ /_/g' > "$file"

			# set the cluster output path
			#nonChimera="${file%.fasta}_nonChimera"

			# cluster at 99 similarity
			usearch -cluster_fast "$file" -id 0.99 -consout "${file%.fasta}_amplicon" -sizeout > /dev/null 2>&1

			# run the de novo chimera removal
			usearch -uchime_denovo "${file%.fasta}_amplicon" -nonchimeras "${file%.fasta}_nonchime" > /dev/null 2>&1

			# resize the chimera output
			Resize_NonChimera "${file%.fasta}_nonchime" > "${file%.fasta}_nonchime.fasta"

			# ZIP the results and remove the redundant files
			zip -q -9 "$temp_zip" "${file%.fasta}_nonchime.fasta"
			rm "${file%.fasta}"*
		fi
	done
	# move the temp zip file to the galaxy output path
	mv "$temp_zip" "$3"

else
	# replace the spaces in the fasta headers
	sed -i 's/ /_/g' "$2"

	# cluster at 99 similarity
	usearch -cluster_fast "$2" -id 0.99 -consout "${3}_amplicon" -sizeout > /dev/null 2>&1

	# run the de novo chimera removal
	usearch -uchime_denovo "${3}_amplicon" -nonchimeras "${3}_nonchime" > /dev/null 2>&1

	# resize the chimera output
	Resize_NonChimera "${3}_nonchime" > "$3"

	# remove the temp files
	rm "${3}_"*
fi
