#!/bin/bash
# shopt -s nullglob
while IFS=, read Ver Plate Well Location Organism Tissue Condition Plate_Well Status Library Replicate
do
    echo "$Ver $Plate $Well $Location $Organism $Tissue $Condition $Plate_Well $Status $Library $Replicate"
    if [ ! -z "$Library" ]
    then
        file=`find . -name "$Library*.fastq.gz"`
        if [ ! -z "$file" ]
        then
            ext=".fastq.gz"
            newfile="$Condition-0${Replicate}-$Status-$Library.fastq.gz"
            # mv "$file" "$1/$Condition-$Library-$Status-0$Replicate.$ext"
            mv $file $newfile
        fi
    fi
done < $2
