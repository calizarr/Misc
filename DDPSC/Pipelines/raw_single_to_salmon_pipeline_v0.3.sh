#!/bin/bash
usage="$(basename "$0") [-h] [-d DIR -t THREADS -i SALMON_INDEX -g EXTENSION_GLOB -l LITERALS] -- running the salmon pipeline from filtering to quantification

where:
    -h		show this help text
    -d		directory for fastq.gz files
    -t		number of cpus requested aka threads
    -i		Salmon index
    -g		Extension glob of files (e.g. .fastq.gz)
    -l		Literal adapter strings to add"

# while getopts ':hdgneat:' option; do
while getopts ':hd:t:i:g:l:' option; do
  case "${option}" in
    h) echo "$usage"
       exit
       ;;
    d) dir=${OPTARG}
       ;;
    t) threads=${OPTARG}
       ;;
    i) index=${OPTARG}
       ;;
    g) ext=${OPTARG}
       ;;
    l) literals=${OPTARG}
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

pipeline="/home/clizarraga/Projects/PyRNA"
#input path to directory containing .fastq.gz RNAseq files
# dir="$1"
# threads=20
# index="$2"
# ext="$3"
# literals="$4"
# cd $1
#start processing all files in folder with fastq.gz file extension
for file in ${dir}/*${ext}
do

    #trim off input file fastq designation for folder/file naming
    b_name=$(echo $file | basename $file)
    d_name=$(echo $file | dirname $file)
    name=$(echo $b_name | sed -r 's/(.*)([_.])(R?[1-2][._])(.*)(.fastq.gz)/\1\2%s\2\4/')
    r_ext=$(echo $b_name | sed -r 's/(.*)([_.])(R?[1-2])([._])(.*)/\3/')
    r_ext=${r_ext::-1}
    prefix=$(printf $name ${r_ext}1)
    echo "File prefix is $prefix"

    #Create output folder
    if [ ! -d 'salmon_pipeline_output/' ]; then
        mkdir "salmon_pipeline_output/"
    fi

    #Check if BBDUK output directory exists, if not, create it
    if [ ! -d 'salmon_pipeline_output/Filtered_BB' ]; then
        mkdir 'salmon_pipeline_output/Filtered_BB'
    fi

    #give feedback about start of run with BBDUK
    echo "Trimming/QC filtering/De-interleaving for file: ${file}"

    #Run BBDUK python script with 40 cores
    if [ -s "salmon_pipeline_output/Filtered_BB/${prefix}/${prefix}.Filtered.fastq.gz" ]
    then
        echo "${file} has already been trimmed. Attempting TPM calculation."
    else
        echo "Trimming/QC filtering/De-interleaving file: ${file}"
        # python $pipeline/trim_adapters_bb.py -nT $threads -input_file $file -outdir salmon_pipeline_output/Filtered_BB/${prefix} -mah 30G -bbduk_conf $pipeline/trim_adapters_quality_single.txt
	python $pipeline/trim_adapters_bb2.py -nT $threads -input_file $file -outdir salmon_pipeline_output/Filtered_BB/${prefix} -mah 30G -bbduk_conf $pipeline/trim_adapters_quality_single_bbduk2.txt --literal=${literals}

        #give feedback about completion of BBDUK
        echo "Trimming complete. Calculating TPM for ${prefix}."
    fi

    #check if salmon ouput directory exists, if not, create it
    if [ ! -d 'salmon_pipeline_output/results' ]; then
        mkdir 'salmon_pipeline_output/results'
    fi

    #run Salmon (using 40 threads and 100 bootstraps) if the file hasn't be processed before
    if [ -d "salmon_pipeline_output/results/${prefix}" ]
    then
        echo "Salmon has already processed file: ${prefix}."
    else
        mkdir "salmon_pipeline_output/results/${prefix}/"
        mkdir "salmon_pipeline_output/results/${prefix}/salmon/"
        salmon quant -i $index -p $threads --numBootstrap 100 --fldMean 539 --fldSD 273 -l A -o salmon_pipeline_output/results/${prefix}/salmon -r salmon_pipeline_output/Filtered_BB/${prefix}/${prefix}.Filtered.fastq.gz
    fi

    #Check if shared TPM folder exists, if not, create it
    if [ ! -d 'salmon_pipeline_output/all_tpm_outputs' ]; then
        mkdir 'salmon_pipeline_output/all_tpm_outputs'
    fi

    #Rename salmon output files with proper file names
    if [ -s "salmon_pipeline_output/results/${prefix}/named_outputs/${prefix}_quant.sf" ]
    then
        echo "Salmon outputs for ${prefix} have already been renamed."
    else
        mkdir "salmon_pipeline_output/results/${prefix}/named_outputs/"
        cp "salmon_pipeline_output/results/${prefix}/salmon/quant.sf" "salmon_pipeline_output/results/${prefix}/named_outputs/${prefix}_quant.sf"
        cp "salmon_pipeline_output/results/${prefix}/salmon/cmd_info.json" "salmon_pipeline_output/results/${prefix}/named_outputs/${prefix}_cmd_info.json"
    fi

    #move TPM output to shared folder
    if [ -s "salmon_pipeline_output/all_tpm_outputs/${prefix}_quant.sf" ]
    then
        echo "${prefix} TPM file already in merged folder."
    else
        cp "salmon_pipeline_output/results/${prefix}/named_outputs/${prefix}_quant.sf" "salmon_pipeline_output/all_tpm_outputs/"
    fi
done
