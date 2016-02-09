#!/bin/bash

cd /home/galaxy/GenBank/

update_blastdb --passive nt

for i in *.gz; do tar -xzvf $i; rm $i; done

#/home/galaxy/Tools/GetUpdate/GetJunkGI.py > junk.gi.txt

#blastdbcmd -db nt -entry all -outfmt %g > allseq.gi.txt

#comm -23 <(sort allseq.gi.txt) <(sort junk.gi.txt) > clean.gi.txt

#blastdb_aliastool -gilist clean.gi.txt -dbtype nucl -db nt -out nt_clean -title nt_clean
