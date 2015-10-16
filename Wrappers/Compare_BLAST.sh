#!/bin/bash

# if the provided file is in zip format
if [ "$1" == "zip" ]
then
	# set temp file that will contain the krona input
	temp=$(mktemp -u XXXXXX.tsv)

	# contain a file list for the files that will be fed into the Compare_BLAST script
	flist=""

	IFS=$'\n'
	# get all the tsv file from the zip
	for tsv in $(zipinfo -1 "$8")
	do
		IFS=$' \t\n'
		output=$(echo "$tsv" | sed 's/.filtered.*//')
		echo "$tsv" "$output"
		# unzip the blast to the tsv file, when unzipping the BLAST
		# data is automatically filtered to only use the first BLAST
		# hit per cluster
		unzip -p "$8" "$tsv" | sed '1d' | sort -u -k1,1 > "${output}"

		# add the file to the file list
		flist+="${output} "

		if [ "$2" != "-A" ]
		then
			# convert the tsv files and set cluster size to 1
			cut -f11 "$output" | sed -e 's/ \/ /\t/g' | sed -e "s/\t/\t${output%.*}\t1\t/1" >> "$temp"
		else
			# convert the tsv file to the krona format while
			# maintaining the cluster size
			cut -f2,12 "$output" | sed -e 's/ \/ /\t/g' | sed -e "s/\t/\t${output%.*}\t/1" >> "$temp"
		fi
	done

	echo $flist

	# Run the Compare blast script
	Compare_BLAST "$6" "$2" $flist

	head "$6"

	# create the krona html file with or without abundance based on the user setting
	if [ "$2" != "-A" ]
	then
	        ktImportText -o "$7" -q "$temp" > /dev/null 2>&1
	else
		ktImportText -o "$7" "$temp" > /dev/null 2>&1

		# set the rank limits for the heatmap
		rankname=$(echo "$4" | cut -f1 -d "-")
		rankpos=$(echo "$4" | cut -f2 -d "-")

		# create an ordered or unordered heatmap based on user settings
		if [ "$5" == "order" ]
		then
			heatmap_BLAST.R "$6" "${3}.png" "$rankname" "$rankpos" "order" > /dev/null 2>&1
		else
			heatmap_BLAST.R "$6" "${3}.png" "$rankname" "$rankpos" "unorder" > /dev/null 2>&1
		fi
		mv "${3}.png" "$3"
	fi

	# remove the temp file
	rm "$temp" $flist


# if a non-zipped BLAST file is provided
else
	# create a temp file which will contain the input for krona
	temp=$(mktemp -u XXXXXX.tsv)

	# contain a file list for the files that will be fed into the Compare_BLAST script
	flist=""

	# Go through the list of input files
	for input_file in "${@:8}"
	do
		blast=$(echo "$input_file" | cut -f1 -d ",")
		name=$(echo "$input_file" | cut -f2 -d "," | sed -e 's/ /_/g' | cut -f1 -d ".")
		fblast=$(echo "$name" | sed 's/.filtered.*//')

		# temp BLAST
		temp_blast=$(mktemp -u XXXXXX.tsv)

		# only the first BLAST hit per cluster is used
		sed '1d' "$blast" | sort -u -k1,1 > "$fblast"

		# add the filtered blast to the file list
		flist+="${fblast} "

		# check if the user provided a BLAST file with cluster sizes
		if [ "$2" != "-A" ]
		then
			# convert the BLAST file without the cluster sizes
			cut -f11 "$fblast" | sed -e 's/ \/ /\t/g' | sed -e "s/\t/\t$name\t/1" >> "$temp"
		else
			# convert the BLAST file to the input format required by krona
			# while maintaining the cluster sizes
			cut -f2,12 "$fblast" | sed -e 's/ \/ /\t/g' | sed -e "s/\t/\t$name\t/1" >> "$temp"
		fi
		echo $flist
	done

	# Run the Compare blast script
	Compare_BLAST "$6" "$2" $flist

	# create the krona html file with or without the abundance based on the user setting
	if [ "$2" != "-A" ]
	then
		ktImportText -o "$7" -q "$temp" > /dev/null 2>&1
	else
		ktImportText -o "$7" "$temp" > /dev/null 2>&1

		# set the rank limits for the heatmap
		rankname=$(echo "$4" | cut -f1 -d "-")
		rankpos=$(echo "$4" | cut -f2 -d "-")

		# generate an ordered or unordered heatmap (based on user setting)
		if [ "$5" == "order" ]
		then
			heatmap_BLAST.R "$6" "${3}.png" "$rankname" "$rankpos" "order" > /dev/null 2>&1
		else
			heatmap_BLAST.R "$6" "${3}.png" "$rankname" "$rankpos" "unorder" > /dev/null 2>&1
		fi
		mv "${3}.png" "$3"
	fi

	# remove the temp file
	rm "$temp" $flist
fi
