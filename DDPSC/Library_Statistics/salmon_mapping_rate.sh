#!/bin/bash
echo "Library,Mapping Rate"
directory="$1"
find $1 -name "salmon_quant.log" | xargs -I {} bash -c 'name=$(dirname {});echo ${name} | sed -e "s/.*\/results\/\(.*\)\/salmon\/logs/\1/" | xargs -I {} printf "%s," {};grep -Po "Mapping rate = \d+\.\d+%" {} | grep -Po "\d+\.\d+%"'
