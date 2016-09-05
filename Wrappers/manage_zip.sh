#!/bin/bash

# display ZIP content
if [ "$1" == "display" ]
then
	unzip -l "$2" > "$3"

# ZIP set of files provided by user or expand current ZIP file
elif [ "$1" == "create" ] || [ "$1" == "expand" ]
then
	if [ "$1" == "create" ]
	then
		# Create a new ZIP archive
		zip -q -9 - $(echo "$3" | tr ',' ' ') > "$2"
	else
		# Add files to an existing archive
		zip -q -9 "$2" $(echo "$3" | tr ',' ' ')
	fi

	# go throught the provided file list and rename the files in the
	# ZIP archive
	for var in "${@:4}"
	do
		# set the old and new file names, required for renaming
		old=${var%dat,*}dat
		new=${var#*dat,}

		# check if the file already has an extension
		if [[ $new =~ "." ]]
		then
			# if so rename
			printf "@ ${old:1}\n@=${new// /-}\n" | zipnote -w "$2"
		# if not scan the files for obvious extensions (fasta / fastq)
		# and add them to the new name
		else
			# first check if the file contains sequences
			if [[ "ATCG" =~ $(sed -n '2p' $old | grep -o "^.") ]]
			then
				# if yes check for the headers
				# first if it is a fasta file
				if [[ ">" == $(head -n 1 $old | grep -o "^.") ]]
				then
					format=".fasta"
				# or secondly a fastq file
				elif [[ "@" == $(head -n 1 $old | grep -o "^.") ]]
				then
					format=".fastq"
				# if neither it is saved as txt
				else
					format=".txt"
				fi
			# if no obvious sequences are found, the format is txt
			else
				format=".txt"
			fi
			# rename with the appropriate extension
			printf "@ ${old:1}\n@=${new// /-}${format}\n" | zipnote -w "$2"
		fi
	done

# Extract (sub)set of file from a ZIP
elif [ "$1" == "unpack" ]
then
	IFS=$'\t\n'
	# Parse through the list of files found in the zip.
	for file in $(zipinfo -1 "$2")
	do
		if [ "$5" != "" ]
		then
			# if the user provided a set of files or regexes for matching, use these
			for match in $(echo "$5" | sed 's/__cn__/\t/g' | sed 's/\*/.\*/g')
			do
				# compare each user match name to all files in the zip
				if [[ $file =~ $match ]]
				then
					# if a file matches unzip it, spaces are replaced
					unzip -p "$2" $file > "primary_$4_"$(echo ${file%.*} | sed 's/_/-/g' |\
					sed 's/ /-/g')"_visible_"$(echo ${file#*.} | sed 's/tsv/tabular/g')

					# if a file is unzipped, break to avoid duplicates
					break
				fi
			done
		else
			# if nothing is provided, unzip everything
			unzip -p "$2" "$file" > "primary_$4_"$(echo ${file%.*} | sed 's/_/-/g' |\
			sed 's/ /-/g')"_visible_"$(echo ${file#*.} | sed 's/tsv/tabular/g')
		fi
	done

# Rename files in ZIP
elif [ "$1" == "rename" ]
then
	# if the user provided a csv file with names, use this for the renaming
	if [ "$3" == "file" ]
	then
		# go through a file and rename everything
		while read line
		do
			old=${line%,*}
			new=${line#*,}
			printf "@ $old\n@=${new// /-}\n" | zipnote -w "$2"
		done < "$4"
	# if no file is provided, use the user provided regex'es
	elif [ "$3" == "regex" ]
	then
		# go through the zip file and match every file against the
		# provided regexes, rename if match is found
		IFS=$'\t\n'
		for file in $(zipinfo -1 "$2")
		do
			# for each regex provided
			for regex in $(echo "$4" | sed 's/__cn__/\t/g')
			do
				IFS=$' \t\n'
				match=${regex%/*}
				sub=${regex#*/}
				# check if it matches to a file
				if [[ $file =~ ${match//\*/.\*} ]]
				then
					# if so, rename the file in zip with the regex
					new_file=${file//$match/$sub}
					printf "@ $file\n@=${new_file// /-}\n" | zipnote -w "$2"
					# and break to avoid duplicates
					break
				fi
			done
		done
	fi

# Delete files in ZIP
elif [ "$1" == "delete" ]
then
	# delete items in the zip that match with the filenames /
	# regexes provided by the user
	items=$(echo "$3" | sed 's/__cn__/ /g')
	zip "$2" -d $items

# Create zip containing a subset of files from an other zip
elif [ "$1" == "subset" ]
then
	# files that match use user provided filenames / regex'es are copied
	# to a new zip file
	zip -9 -U "$2" $(echo "$4" | sed 's/__cn__/ /g' | sed 's/__dq__/\"/g' | sed 's/__ob__/\[/g' | sed 's/__cb__/\]/g') -O "$3"

# If nothing matches
else
	# echo the commands (backup)
	echo "$1"
fi
