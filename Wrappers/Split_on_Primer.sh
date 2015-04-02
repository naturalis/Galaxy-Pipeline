#!/bin/bash

# If the user entered the primers in the text form, save them to a temporary file
# (Required for the Split_on_primer script)
if [ "$4" == "text" ]
then
	# Create a temporary file for the user provided primers
	temp_primer=$(mktemp)
	# Split the text field data and write them to the temp file
	printf $(echo "$5" | sed 's/__cr____cn__/\\n/g') > $temp_primer
	# set the arguments so that the temp file replaces the text argument
	set -- "${@:1:4}" "$temp_primer" "${@:6}"
fi

# if a zip file is submitted
if [ "$1" == "zip" ]
then
	# Create a temporary zip file
	temp_zip=$(mktemp -u XXXXXX.zip)
	IFS=$'\t\n'
	# for each file in the zip
	for file in $(zipinfo -1 "$2")
	do
		# check if file is fasta / fastq
		if [[ "@>" =~ $(unzip -p "$2" "$file" | head -n 1 | grep -o "^.") ]]
		then
			IFS=$' \t\n'
			# Create a temporary seq fiel
			ziped=$(mktemp)
			# Write the reads to the temp seq file
			unzip -p "$2" "$file" > $ziped
			# replace spaces in the filenames, space-less names are required
			# in order to retrieve the files after splitting.
			file="${file// /-}"
			# Run the Split on primer tool, capture the file list output
			Split_files=$(Split_on_Primer -f $ziped -p "$5" -m "$6" -s "$7" ${8})
			# for each filename in the filelist produced by the Split_on_Primer tool
			for split in $Split_files
			do
				# for every output file, check if it contains reads
				lines=$(wc -l $split | awk -F$" " '{print $1}')
				if [ $lines -eq "0" ]
				then
					# if empty: remove
					rm $split
				else
					# get the output file and zip it to the temp zip file
					new=$(echo ${split/${ziped%.*}/${file%.*}} | sed -e "s/\..*/.${file#*.}/")
					mv $split $new
					zip -q -9 "$temp_zip" $new
					# remove the left over file
					rm $new
				fi
			done
			# remove the used temp zip file
			rm $ziped
		fi
	done
	# move the temp zip to the output zip location so that galaxy can find it
	mv $temp_zip $9

# if non-zipped data is suplied
else
	# Run the Split tools and capture the split filepaths
	Split_files=$(Split_on_Primer -f "$2" -p "$5" -m "$6" -s "$7" ${8})
	# for each split file produced
	for file in $Split_files
	do
		# Parse through the output files and change the name so it gets recognized by galaxy
		lines=$(wc -l $file | awk -F$" " '{print $1}')
		if [ $lines -eq "0" ]
		then
			# remove the empty file
			rm $file
		else
			# Set the new name so Galaxy can capture the files in the history
			new_name="primary_${10}_"$(echo "${file%.*}" | sed 's/.*\///' | cut -f3- -d - | sed 's/_/-/g' )"_visible_$1"
			# change the split output name to the new name
			mv $file $new_name
		fi
	done
fi

# If the primers were submitted in xml text box, remove the
# temp primer file that was created
if [ "$4" == "text" ]
then
	rm "$temp_primer"
fi
