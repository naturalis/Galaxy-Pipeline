#!/bin/bash

# check the CITES database, if local update if needed, if not present download
# set the script arguments afterwards so the new database is used regardless of 
# user imput.
if [ "${10}" == "local" ]
then
	# force download or check download the user provided databse, skip if argument
	# is set to avoid download
	if [ "${12}" == "force" ]; then
		/home/galaxy/Tools/HTS-barcode-checker/src/Retrieve_CITES.py -f -db "${11}" > /dev/null 2>&1
	elif [ "${12}" == "check" ]; then
		/home/galaxy/Tools/HTS-barcode-checker/src/Retrieve_CITES.py -db "${11}" > /dev/null 2>&1
	fi
	# set the script arguments with the new CITES path
	set -- "${@:1:9}" "${11}" "${@:13}"
else
	# if no database is provided, get the default CITES_db from the identify tool folder
	CITES_db="/home/galaxy/ExtraRef/CITES_db.csv"
	# run the Retrieve CITES script to update the default file if needed
	/home/galaxy/Tools/HTS-barcode-checker/src/Retrieve_CITES.py -db "${CITES_db}" > /dev/null 2>&1
	# copy the default CITES db so it can be included in the galaxy history
	cp "${CITES_db}" "primary_${11}_CITES-db_visible_csv"
	# set the script arguments with the new CITES path
	set -- "${@:1:9}" "primary_${11}_CITES-db_visible_csv" "${@:12}"
fi

# for local blasting, check if the hs is =< 20
if [ "$4" != "-lb" ] && [ "$6" -gt 20 ]; then
	# set to max 20 if above 20
	set -- "${@:1:5}" "20" "${@:7}"
fi



# If a zip file is provided by the user
if [ "$1" == "zip" ]
then
	# set temp zip output file
	temp_zip=$(mktemp -u XXXXXX.zip)

	# go through the zip file and extract the fasta files required for blasting
	# all .clstr file are skipped if provided
	IFS=$'\n'
	for file in $(zipinfo -1 "$2" | grep -vE ".clstr|.txt")
	do
		IFS=$' \t\n'
		# check if the file is a fasta file (ie check if a fasta header is present)
		if [ "$(unzip -p "$2" "$file" | head -n 1 | grep -o "^.")" == ">" ]
		then
			# unzip the reads to the temp file
			unzip -p "$2" "$file" | sed 's/ /_/g' > "$file"
			# set the output path
			output="${file%.*}".tsv

			# Run the HTS-barcode-checker command and capture the output
			if [ "$4" == "-lb" ]; then
				# local commanand
				HTS-Barcode-Checker -i "$file" -o "$output" -lb -tf /home/galaxy/ExtraRef/taxonid_names.tsv -bd "$5" -hs "$6" -mi "$7" -mc "$8" -me "$9" -ad -cd "${@:10}" > /dev/null 2>&1
			else
				# check if the file contains less then a 100 reads, if more skip the online blast
				# to prevent flooding of the ncbi servers
				if [ $(grep -c ">" "$file") -le 100 ]; then
					# online command
					HTS-Barcode-Checker -i "$file" -o "$output" -ba "$4" -bd "$5"  -hs "$6" -mi "$7" -mc "$8" -me "$9" -ad -cd "${@:10}" > /dev/null 2>&1
				else
					# if more then a 100 reads, write the following output
					echo "$file contains to many reads for online blasting, switch to local blast" > "$output"
				fi
			fi
			# ZIP the HTS-barcode-checker output files to the temp zip file
			zip -q -9 "$temp_zip" "$output"
			# remove the output files
			rm "$file" "$output"
		fi
	done
	# move the temp zip file to the galaxy output zip file
	mv "$temp_zip" "$3"
# if no zip file is provided, run one of the following commands, the HTS-barcode-checker output is immediatly written to the
# galaxy output filepath provided
else
	if [ "$4" == "-lb" ]; then
		# local blast command
		HTS-Barcode-Checker -i "$2" -o "$3" -lb -tf /home/galaxy/ExtraRef/taxonid_names.tsv -bd "$5" -hs "$6" -mi "$7" -mc "$8" -me "$9" -ad -cd "${@:10}" > /dev/null 2>&1
	else
		# check if the file contains less then a 100 reads, if more skip the online blast
		# to prevent flooding of the ncbi servers
		if [ $(grep -c ">" "$2") -le 100 ]; then
			# online blast command
			HTS-Barcode-Checker -i "$2" -o "$3" -ba "$4" -bd "$5"  -hs "$6" -mi "$7" -mc "$8" -me "$9" -ad -cd "${@:10}" > /dev/null 2>&1
		else
			# if more then a 100 reads, write the following output
			echo "$file contains to many reads for online blasting, switch to local blast" > "$3"
		fi
	fi
fi
