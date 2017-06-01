#!/bin/bash
usage="$(basename "$0") [-h] [-f error log] -- creates the stats files etc.

where:
	-h	show this help text
	-f	filename of the error log
"

while getopts ':hf:' option;do
    case "${option}" in
	h) echo "$usage"
	   exit
	   ;;
	f) ERROR_LOG=${OPTARG}
	   ;;
	:) printf "missing argument for -%s\n" "$OPTARG" >&2
	   echo "$usage" >&2
	   exit 1
	   ;;
	\?) printf "illegal option: -%s\n" "$OPTARG" >&2
	    echo "$usage" >&2
	    exit 1
	    ;;
    esac
done
shift $((OPTIND - 1))

if [[ -z $ERROR_LOG ]]
then
    printf "Need the error log to produce the output file"
    echo "$usage" >&2
    exit 1
fi

## Getting the required portions of the error log and creating two temp files
filetemp=$(mktemp $(pwd)/filetemp.XXX.txt)
statstemp=$(mktemp $(pwd)/statstemp.XXX.txt)

## Assigning the temp files with information
grep -Po "in=.*fastq.gz\s" $ERROR_LOG | sed 's/in=//' | xargs -I {} basename {} > $filetemp
grep -A5 "Input:" $ERROR_LOG | sed '/--/d' > $statstemp

pythonScript=$(echo "$0" | sed 's/sh$/py/')

python $pythonScript -f1 $filetemp -f2 $statstemp -n1 1 -n2 6

rm "$filetemp"
rm "$statstemp"
