#!/bin/bash

#echo "$@"

# cat to the output file
cat "${@:2}" > "$1"
