#!/usr/bin/env python

# reduce the names.dmp file to just the taxonid - scientific name
import sys

processed = {}
outfile = open(sys.argv[2], 'w')
for line in open(sys.argv[1]):
	if 'scientific name' not in line: continue
	line = line.split('\t')
	if line[0] not in processed:
		outfile.write('{0}\t{1}\n'.format(line[0],line[2]))
		processed[line[0]] = ''
outfile.close()
