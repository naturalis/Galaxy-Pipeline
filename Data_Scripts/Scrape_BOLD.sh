#!/bin/bash

# Switch to the Extra_Ref folder
cd /home/galaxy/Extra_Ref

# Obtain a list of all the Kingdoms located on BOLD
for sp in $(wget -O - -q http://www.barcodinglife.org/index.php/TaxBrowser_Home | grep taxid | grep -o "[0-9]\">.* " | cut -f2 -d ">")
do
	# Use wget to download the file from the BoLD API and append it to the temporary fasta file
	echo $sp
	wget -O - http://www.boldsystems.org/index.php/API_Public/sequence?taxon=$sp > temp_fasta.fasta #> temp_BoLD.fasta
	# variable sleep time (sqrt^3 of # num of sequences downloaded)
	mr=$(seq=$(grep -c ">" temp_fasta.fasta); echo "sqrt(sqrt($seq)*2)"| bc)
	echo $mr
	#echo "sleeping for ${mr} min"
	sleep ${mr}m
	cat temp_fasta.fasta >> temp_BoLD.fasta
done

# Create the unfiltered file + BLAST database
/home/galaxy/Tools/GetUpdate/Clean_FASTA.py -f temp_BoLD.fasta > BoLD_combined_unfiltered.fasta
makeblastdb -in BoLD_combined_unfiltered.fasta -dbtype nucl

# Create the filtered file + BLAST database
/home/galaxy/Tools/GetUpdate/Clean_and_Filter_FASTA.py -f temp_BoLD.fasta > BoLD_combined_filtered.fasta
makeblastdb -in BoLD_combined_filtered.fasta -dbtype nucl

# Remove the temporary sequence file
rm temp_BoLD.fasta
rm temp_fasta.fasta
