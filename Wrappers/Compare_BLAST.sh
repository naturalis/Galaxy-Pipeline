#!/bin/bash

# if the provided file is in zip format
if [ "$1" == "zip" ]
then
	# set the variable that will contain the seperate krona input
	stemp=""

	# contain a file list for the files that will be fed into the Compare_BLAST script
	flist=""

	IFS=$'\n'
	# get all the tsv file from the zip
	for tsv in $(zipinfo -1 "$9")
	do
		IFS=$' \t\n'
		output=$(echo "$tsv" | sed 's/.filtered.*//')

		# unzip the blast to the tsv file, when unzipping the BLAST
		# data is automatically filtered to only use the first BLAST
		# hit per cluster
		unzip -p "$9" "$tsv" | sed '1d' | sort -u -k1,1 > "${output}"

		# add the file to the file list krona merged file
		flist+="${output} "
		stemp+="${output}-K "

		if [ "$2" != "-A" ]
		then
			# convert the tsv files and set cluster size to 1
			# save to both the merged and seperate files
			cut -f11 "$output" | sed -e 's/ \/ /\t/g' | sed -e "s/^/${output%.*}\t/" >> "merged.tsv"
			cut -f11 "$output" | sed -e 's/ \/ /\t/g' > "${output}-K"
		else
			# convert the tsv file to the krona format while
			# maintaining the cluster size, save to both
			# the merged and seperate files
			cut -f2,12 "$output" | sed -e 's/ \/ /\t/g' | sed -e "s/\t/\t${output%.*}\t/1" >> "merged.tsv"
			cut -f2,12 "$output" | sed -e 's/ \/ /\t/g' > "${output}-K"
		fi
	done

	# Run the Compare blast script
	Compare_BLAST "$6" "$2" $flist

	# create the krona html files (merged and seperate) with or
	# without abundance based on the user setting
	if [ "$2" != "-A" ]
	then
	        ktImportText -o "$7" -q $stemp > /dev/null 2>&1
		ktImportText -o "$8" -q "merged.tsv" > /dev/null 2>&1
	else
		ktImportText -o "$7" $stemp > /dev/null 2>&1
		ktImportText -o "$8" "merged.tsv" > /dev/null 2>&1
	fi

	# set the rank limits for the heatmap
	rankname=$(echo "$4" | cut -f1 -d "-")
	rankpos=$(echo "$4" | cut -f2 -d "-")

	# create an ordered or unordered heatmap based on user settings
	if [ "$5" == "order" ]
	then
		Heatmap_BLAST "$6" "${3}.png" "$rankname" "$rankpos" "order" > /dev/null 2>&1
	else
		Heatmap_BLAST "$6" "${3}.png" "$rankname" "$rankpos" "unorder" > /dev/null 2>&1
	fi
	mv "${3}.png" "$3"

	# remove the temp file
	rm $(printf $stemp) $(printf $flist | sort -u) "merged.tsv"

# if a non-zipped BLAST file is provided
else
	# create a variable which will contain the input files for the seperate krona run
	stemp=""

	# contain a file list for the files that will be fed into the Compare_BLAST script
	flist=""

	# Go through the list of input files
	for input_file in "${@:9}"
	do
		blast=$(echo "$input_file" | cut -f1 -d ",")
		name=$(echo "$input_file" | cut -f2 -d "," | sed -e 's/ /_/g' | sed -e 's/\./_/' | cut -f1 -d ".")
		fblast=$(echo "$name" | sed 's/.filtered.*//')

		# temp BLAST
		temp_blast=$(mktemp -u XXXXXX.tsv)

		# only the first BLAST hit per cluster is used
		sed '1d' "$blast" | sort -u -k1,1 > "$fblast"

		# add the filtered blast to the file list
		flist+="${fblast} "
		stemp+="${fblast}-K "

		# check if the user provided a BLAST file with cluster sizes
		if [ "$2" != "-A" ]
		then
			# convert the BLAST file without the cluster sizes
			# save to both the merged and seperate file
			cut -f11 "$fblast" | sed -e 's/ \/ /\t/g' | sed -e "s/^/$name\t/" >> "merged.tsv"
			cut -f11 "$fblast" | sed -e 's/ \/ /\t/g' > "${fblast}-K"
		else
			# convert the BLAST file to the input format required by krona
			# while maintaining the cluster sizes, save to both the merged
			# and seperate file
			cut -f2,12 "$fblast" | sed -e 's/ \/ /\t/g' | sed -e "s/\t/\t$name\t/1" >> "merged.tsv"
			cut -f2,12 "$fblast" | sed -e 's/ \/ /\t/g' > "${fblast}-K"
		fi
	done

	# Run the Compare blast script
	Compare_BLAST "$6" "$2" $flist

	# create the krona html file with or without the abundance based on the user setting
	if [ "$2" != "-A" ]
	then
		ktImportText -o "$7" -q $stemp > /dev/null 2>&1
		ktImportText -o "$8" -q "merged.tsv" > /dev/null 2>&1
	else
		ktImportText -o "$7" $stemp > /dev/null 2>&1
		ktImportText -o "$8" "merged.tsv" > /dev/null 2>&1
	fi

	# set the rank limits for the heatmap
	rankname=$(echo "$4" | cut -f1 -d "-")
	rankpos=$(echo "$4" | cut -f2 -d "-")

	# generate an ordered or unordered heatmap (based on user setting)
	if [ "$5" == "order" ]
	then
		Heatmap_BLAST "$6" "${3}.png" "$rankname" "$rankpos" "order" > /dev/null 2>&1
	else
		Heatmap_BLAST "$6" "${3}.png" "$rankname" "$rankpos" "unorder" > /dev/null 2>&1
	fi
	mv "${3}.png" "$3"

	# remove the temp file
	rm $(printf $stemp) $(printf $flist | sort -u) "merged.tsv"
fi
