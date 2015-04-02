#!/bin/bash

cd /home/galaxy/GenBank/

update_blastdb --passive nt

for i in *.gz; do tar -xzvf $i; rm $i; done
