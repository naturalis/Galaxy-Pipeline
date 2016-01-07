#!/usr/bin/env python

# Usage: Clean_FASTA -f [sequence file] > [output file]

# author: Youri Lammers
# contact: youri.lammers@naturalis.nl / youri.lammers@gmail.com

# import the modules used by the script
import os, argparse, itertools, re

# Retrieve the commandline arguments
parser = argparse.ArgumentParser(description = 'Clean FASTA data')

parser.add_argument('-f', '--sequence_file', metavar='Sequence file', dest='sequence', type=str,
			help='The sequence file in fasta format.')
args = parser.parse_args()

def removeNonAscii(s):
	# Strip all non-ASCII characters from the FASTA header.
	return "".join(i for i in s if ord(i)<128)

def extract_sequences():

	# open the sequence file submitted by the user, get 
	sequence_file = open(args.sequence)

	# remove non ATCG characters from the sequence file 
	# and non ASCII characters from the header

	# parse throught the file
        lines = (x[1] for x in itertools.groupby(sequence_file, key=lambda line: line[0] == '>'))

	# walk through the header and obtain the sequences
        for headers in lines:
		header = removeNonAscii(headers.next().strip())
		sequence = ''.join(line.strip() for line in lines.next())
		sequence = re.sub('[^ATCGU]', '', sequence)
		sequence = re.sub('U', 'T', sequence)
				
		# yield the header + sequence
		yield [header, sequence]


def main ():

	# get a read from the input file
	for read in extract_sequences():

		# print the sequence (max 60 nucl per line)
		print '{0}\n{1}'.format(read[0].replace(' ','_'),'\n'.join([read[1][i:i+60] for i in range(0, len(read[1]), 60)]))


if __name__ == '__main__':
	main()

