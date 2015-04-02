#!/bin/bash

# check if a local database will be used for BLASTING.
# If so alter the paths so that the local blast tool
# can find the reference databases.
if [ "$8" == "-lb" ]
then
	temp=""
	# walk through the list of selected reference
	# databases. Note! These paths might have to
	# be adjusted for your system.
	for db in $(echo "$9" | tr "," "\t")
	do
		# if the nt database is selected, alter
		# the path
		if [ "$db" == "nt" ]
		then
			temp+="/home/galaxy/GenBank/nt "
		# else, alter the path based on the 
		# extra_ref folder
		else
			temp+="/home/galaxy/Extra_Ref/"$db" "
		fi
	done
	temp=$(echo $temp | sed 's/ $//')
	# alter the bash arguments with the new paths.
	set -- "${@:1:8}" "$temp"
else
	# set the max hs size to 20 if larger
	if [ "$4" -gt 20 ]; then
		set -- "${@:1:3}" "20" "${@:5}"
	fi
fi

# If a zip file is provided, run the blast tool for each zip file
# and return the results in a new zip.
if [ "$1" == "zip" ]
then
	# set temp zip output file
	temp_zip=$(mktemp -u XXXXXX.zip)

	# go through the zip file and extract the fasta files required for blasting
	# note: the .clstr files are skipped
	IFS=$'\n'
	for file in $(zipinfo -1 "$2" | grep -vE ".clstr|.txt")
	do
		IFS=$' \t\n'
		# check if the file is indead a fasta file based on the header
		if [ "$(unzip -p "$2" "$file" | head -n 1 | grep -o "^.")" == ">" ]
		then
			# unzip the reads to the temp file
			unzip -p "$2" "$file" | sed 's/ /_/g' > "$file"
			# set the blast output path
			output="${file%.*}".tsv

			# Set up the BLAST command and capture the output
			if [ "$8" == "-lb" ]; then
				# local commanand / SET OUTPUT FILE
				BLAST_wrapper -i "$file" -o "$output" -bd "${@:9}" -lb -tf /home/galaxy/Extra_Ref/taxonid_names.tsv -hs "$4" -mi "$5" -mc "$6" -me "$7" > /dev/null 2>&1
			else
				# check if the file contains less then a 100 reads, if more skip the online blast
				# to prevent flooding of the ncbi servers
				if [ $(grep -c ">" "$file") -le 100 ]; then
					# online command
					BLAST_wrapper -i "$file" -o "$output" -bd "$9" -ba "$8" -hs "$4" -mi "$5" -mc "$6" -me "$7" > /dev/null 2>&1
				else
					# if more then a 100 reads, write the following output
					echo "$file contains to many reads for online blasting, switch to local blast" > "$output"
				fi
			fi
			# add the output file to the temp zip file
			zip -q -9 "$temp_zip" "$output"
			# remove the output file
			rm "$file" "$output"
		fi
	done
	# move the temp zip file to the file location / name expected by galaxy
	mv "$temp_zip" "$3"

# when dealing with a normal fasta file (non zipped) run the blast command.
# the output is directly written to the expected location
else
	if [ "$8" == "-lb" ]; then
		# the command for local blasting
		BLAST_wrapper -i "$2" -o "$3" -bd "${@:9}" -lb -tf /home/galaxy/Extra_Ref/taxonid_names.tsv -hs "$4" -mi "$5" -mc "$6" -me "$7" > /dev/null 2>&1
	else
		# check if the file contains less then a 100 reads, if more skip the online blast
		# to prevent flooding of the ncbi servers
		if [ $(grep -c ">" "$2") -le 100 ]; then
			# online command
			BLAST_wrapper -i "$2" -o "$3" -bd "$9" -ba "$8" -hs "$4" -mi "$5" -mc "$6" -me "$7" > /dev/null 2>&1
		else
			# if more then a 100 reads, write the following output
			echo "$file contains to many reads for online blasting, switch to local blast" > "$3"
		fi
	fi
fi
