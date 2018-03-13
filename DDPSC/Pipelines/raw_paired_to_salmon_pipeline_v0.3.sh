#!/bin/bash
# input path to directory containing .fastq.gz RNAseq files
dir="$1"
pipeline="/home/clizarraga/Projects/PyRNA"
threads=40
index="$2"
ext="$3"
# paired="$4"
interleaved="$4"
literals="$5"
adapters=$HOME/usr/local/bbmap/resources/truseq_rna.fa.gz
# start processing all files in folder with fastq.gz file extension
for file in ${dir}/*${ext}
do
    b_name=$(echo $file | basename $file)
    d_name=$(echo $file | dirname $file)
    if [ "$interleaved" != "t" ]; then
        # trim off input file fastq designation for folder/file naming
        name=$(echo $b_name | sed -r 's/(.*)([_.])(R?[1-2][._])(.*)(.fastq.gz)/\1\2%s\2\4/')
        r_ext=$(echo $b_name | sed -r 's/(.*)([_.])(R?[1-2])([._])(.*)/\3/')
        r_ext=${r_ext::-1}
        prefix=$(printf $name ${r_ext}1)
        echo "File prefix is $prefix"
    elif [ "$interleaved" == "t" ]; then
        name=$(echo $b_name | sed -r 's/(.*)(.fastq.gz)/\1/')
        echo "Name is $name"
    fi
       
    # Create output folder
    if [ ! -d 'salmon_pipeline_output/' ]; then
        mkdir "salmon_pipeline_output/"
    fi

    # Check if BBDUK output directory exists, if not, create it
    if [ ! -d 'salmon_pipeline_output/Filtered_BB' ]; then
        mkdir 'salmon_pipeline_output/Filtered_BB'
    fi

    # give feedback about start of run with BBDUK
    echo "Trimming/QC filtering/De-interleaving for file: ${file}"

    # Run BBDUK python script with 40 cores
    if [ -s "salmon_pipeline_output/Filtered_BB/${name}/${name}.Filtered.R1.fastq.gz" ]
    then
        echo "${file} has already been trimmed. Attempting TPM calculation."
    else
        echo "Trimming/QC filtering/De-interleaving file: ${file}"
        if [ "$interleaved" == "t" ]
        then
            python $pipeline/trim_adapters_bb2.py -nT $threads -input_file $file -outdir salmon_pipeline_output/Filtered_BB/${name} -mah 30G -paired -inter $interleaved -bbduk_conf $pipeline/trim_adapters_quality_paired_bbduk2.txt --literal=${literals}
        else
            python $pipeline/trim_adapters_bb2.py -nT $threads -input_file ${dir}/${name}${r_ext}1.fastq.gz ${dir}/${name}${r_ext}2.fastq.gz -outdir salmon_pipeline_output/Filtered_BB/${name} -mah 30G -paired -bbduk_conf $pipeline/trim_adapters_quality.txt -lit ${literals}
        fi
        # give feedback about completion of BBDUK
        echo "Trimming complete. Calculating TPM for ${name}."
    fi

    # check if salmon ouput directory exists, if not, create it
    if [ ! -d 'salmon_pipeline_output/results' ]; then
        mkdir 'salmon_pipeline_output/results'
    fi

    # run Salmon (using 40 threads and 100 bootstraps) if the file hasn't be processed before
    if [ -d "salmon_pipeline_output/results/${name}" ]
    then
        echo "Salmon has already processed file: ${name}."
    else
        mkdir "salmon_pipeline_output/results/${name}/"
        mkdir "salmon_pipeline_output/results/${name}/salmon/"
        if [ "$interleaved" == "t" ]
        then
            salmon quant -i $index -p $threads --numBootstrap 100 -l A -o salmon_pipeline_output/results/${name}/salmon -1 salmon_pipeline_output/Filtered_BB/${name}/${name}.Filtered.R1.fastq.gz -2 salmon_pipeline_output/Filtered_BB/${name}/${name}.Filtered.R2.fastq.gz
        fi

        # Check if shared TPM folder exists, if not, create it
        if [ ! -d 'salmon_pipeline_output/all_tpm_outputs' ]; then
            mkdir 'salmon_pipeline_output/all_tpm_outputs'
        fi

        # Rename salmon output files with proper file names
        if [ -s "salmon_pipeline_output/results/${name}/named_outputs/${name}_abundance.h5" ]
        then
            echo "Salmon outputs for ${name} have already been renamed."
        else
            mkdir "salmon_pipeline_output/results/${name}/named_outputs/"
            cp "salmon_pipeline_output/results/${name}/salmon/quant.sf" "salmon_pipeline_output/results/${name}/named_outputs/${name}_quant.sf"
            cp "salmon_pipeline_output/results/${name}/salmon/cmd_info.json" "salmon_pipeline_output/results/${name}/named_outputs/${name}_cmd_info.json"
        fi
        # move TPM output to shared folder
        if [ -s "salmon_pipeline_output/all_tpm_outputs/${name}_quant.sf" ]
        then
            echo "${name} TPM file already in merged folder."
        else
            cp "salmon_pipeline_output/results/${name}/named_outputs/${name}_quant.sf" "salmon_pipeline_output/all_tpm_outputs/"
        fi
    fi
done
