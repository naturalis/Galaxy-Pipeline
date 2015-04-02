#!/bin/bash

# if zipped data is provided
if [ "$1" == "zip" ]
then

	# set temp zip output file
	temp_zip=$(mktemp -u XXXXXX.zip)

	IFS=$'\n'
	# for each file in the provided zip file
	for file in $(zipinfo -1 "$4")
	do
		IFS=$' \t\n'
		if [ $(unzip -p "$4" "$file" | head -n 1 | grep -o "^.") == ">" ]
		then
			# unzip the reads to the temp file and replace spaces in
			# the fasta header with underscores
			unzip -p "$4" "$file" | sed 's/ /_/g' > "$file"

			# set the cluster output path
			cluster="${file%.fasta}_clustered"

			# Cluster the fasta file with the provided settings
			cdhit-est -i "$file" -o "$cluster" -c "$2" -T 0 -g 1 -d 0 > /dev/null 2>&1

			# replaces in the cluster output headers, the might cause issues with
			# downstream tools
			sed -i 's/>Cluster />Cluster_/g' "$cluster".clstr # Replace "$cluster".clstr ?

			# Filter the clustered file
			CD-HIT-Filter -f "$cluster" -c "${cluster}.clstr" -m "$3" > /dev/null 2>&1

			# ZIP the results and remove the redundant files
			zip -q -9 "$temp_zip" "$cluster"*min*fasta "${cluster}.clstr"
			rm "$cluster" "${cluster}.clstr" "$file"
		fi
	done
	# move the temp zip file to the galaxy output path
	mv "$temp_zip" "$5"

else
	# replace the spaces in the fasta headers
	sed -i 's/ /_/g' "$4"
	# Run CD-HIT-EST
	cdhit-est -i "$4" -o "$5" -c "$2" -T 0 -g 1 -d 0 > /dev/null 2>&1
	# move the clstr file to galaxy clstr path
	mv "${5}.clstr" "$6"
	# replace the spaces in the cluster fasta file
	sed -i 's/>Cluster />Cluster_/g' "$6"

	# Filter the OTUs with the user provided minimum cluster size
	CD-HIT-Filter -f "$5" -c "$6" -m "$3" > /dev/null 2>&1
	# move the filtered clusters to the output galaxy path
	mv "${5%.*}"*min*fasta "$5"
fi
