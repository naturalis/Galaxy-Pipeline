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
		if [ $(unzip -p "$2" "$file" | head -n 1 | grep -o "^.") == "@" ]
		then
			# unzip the reads to the temp file and replace spaces in
			# the fasta header with underscores
			unzip -p "$2" "$file" | sed 's/ /_/g' > "$file"

			# if ABYSS is selected
			if [ "$4" == "Abyss" ]
			then
				# calculate the k-mer values (min-k, max-k and the steps between)
				mink="$9"
				maxk="${10}"
				step="${11}"
				# check if multiple k-mers are required
				if [[ $step > 1 ]]
				then
					stepv=$((((maxk-mink))/step))
				else
					mink="$maxk"
					stepv="$step"
				fi

				# for each k-mer run abyss
				for ((k="$mink";k<="$maxk";k+="$stepv"))
				do
					# SET OUTPUT FOLDER
					A_temp=$(mktemp -d -u abyss_XXXX)
					transabyss --se "$file" --outdir "$A_temp" --cleanup 3 -c "$6" --pid "$5" --length "$8" --threads 8 -k "$k" > /dev/null 2>&1
					mv "$A_temp"/*final.fa "${file%.*}_${k}_final.fa"
					rm -rf "$A_temp"

				done

				# check if mergering is required
				if [[ $step > 1 ]]
				then

					# run the transabyss merge step
					transabyss-merge --mink "$9" --maxk "${10}" --threads 8 --out "${file%.*}_assembled.fasta" --length "$8" --pid "$7" "${file%.*}"*final.fa > /dev/null 2>&1
					rm "${file%.*}"*final.fa

					zip -q -9 "$temp_zip" "${file%.*}_assembled.fasta"
					rm "${file%.*}_assembled.fasta" "$file"
				else
					# rename the single output file and save
					mv "${file%.*}_"*"_final.fa" "${file%.*}_assembled.fasta"

					zip -q -9 "$temp_zip" "${file%.*}_assembled.fasta"
					rm "${file%.*}_assembled.fasta" "$file"
				fi


			# if SOAP is selected
			else
				# create config file for SOAP
				echo -e "max_rd_len=${8}\n[LIB]\nq=${file}" > "${file%.*}_conf"

				# RUN SOAPdenovo-Trans
				test=$(SOAPdenovo-Trans-127mer all -s "${file%.*}_conf" -o "${file%.*}_graph" -K "$5" -p 8 -d "$7") # SIGSEGV
				if [[ $? -eq 139 ]]; then echo "${file} could not be assembled at k=${5}, please try another value."; fi

				# rename and ZIP result file
				scaf="${file%.*}_assembled.fasta"
				mv "${file%.*}_graph.scafSeq" "$scaf"
				zip -q -9 "$temp_zip" "$scaf"
				rm "$scaf" "$file" "${file%.*}_graph"* "${file%.*}_conf"
			fi
		fi
	done
	# move the temp zip file to the galaxy output path
	mv "$temp_zip" "$3"

else
	# replace the spaces in the fasta headers
	sed -i 's/ /_/g' "$2"

	# IF Abyss is selected
	if [ "$4" ==  "Abyss" ]
	then

		# calculate the k-mer values (min-k, max-k and the steps between)
		mink="$9"
		maxk="${10}"
		step="${11}"
		# check multiple k-mers are required
		if [[ $step > 1 ]]
		then
			stepv=$((((maxk-mink))/step))
		else
			mink="$maxk"
			stepv="$step"
		fi

		# for each k-mer run abyss
		for ((k="$mink";k<="$maxk";k+="$stepv"))
		do
			# SET OUTPUT FOLDER
			A_temp=$(mktemp -d -u abyss_XXXX)
			transabyss --se "$2" --outdir "$A_temp" --cleanup 3 -c "$6" --pid "$5" --length "$8" --threads 8 -k "$k" > /dev/null 2>&1
			mv "$A_temp"/*final.fa "${2%.*}_${k}_final.fa"
			rm -rf "$A_temp"
		done

		# check if merging is required
		if [[ $step > 1 ]]
		then
			# run the transabyss merge step
			transabyss-merge --mink "$9" --maxk "${10}" --threads 8 --out "${2%.*}_assembled.fa" --length "$8" --pid "$7" "${2%.*}"*final.fa > /dev/null 2>&1
			rm "${2%.*}"*final.fa

			mv "${2%.*}_assembled.fa" "$3"
		else
			# save the single output file
			mv "${2%.*}_"*"_final.fa" "$3"
		fi

	# IF SOAP is selected
	else

		# create config file for SOAP
		echo -e "max_rd_len=${8}\n[LIB]\nq=${2}" > "${2%.*}_conf"

		# RUN SOAPdenovo-Trans
		SOAPdenovo-Trans-127mer all -s "${2%.*}_conf" -o "${2%.*}_graph" -K "$5" -p 8 -d "$7" > /dev/null 2>&1
		if [[ $? -eq 139 ]]; then echo "${2} could not be assembled at k=${5}, please try another value."; fi

		# rename and ZIP result file
		mv "${2%.*}_graph.scafSeq" "$3"
		rm "${2%.*}_graph"* "${2%.*}_conf"
	fi
fi
