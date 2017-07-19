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
    if [ ! -d 'kallisto_pipeline_output/' ]; then
        mkdir "kallisto_pipeline_output/"
    fi

    # Check if BBDUK output directory exists, if not, create it
    if [ ! -d 'kallisto_pipeline_output/Filtered_BB' ]; then
        mkdir 'kallisto_pipeline_output/Filtered_BB'
    fi

    # give feedback about start of run with BBDUK
    echo "Trimming/QC filtering/De-interleaving for file: ${file}"

    # Run BBDUK python script with 40 cores
    if [ -s "kallisto_pipeline_output/Filtered_BB/${name}/${name}.Filtered.R1.fastq.gz" ]
    then
        echo "${file} has already been trimmed. Attempting TPM calculation."
    else
        echo "Trimming/QC filtering/De-interleaving file: ${file}"
        if [ "$interleaved" == "t" ]
        then
            python $pipeline/trim_adapters_bb2.py -nT $threads -input_file $file -outdir kallisto_pipeline_output/Filtered_BB/${name} -mah 30G -paired -inter $interleaved -bbduk_conf $pipeline/trim_adapters_quality_paired_bbduk2.txt --literal=${literals}
        else
            python $pipeline/trim_adapters_bb2.py -nT $threads -input_file ${dir}/${name}${r_ext}1.fastq.gz ${dir}/${name}${r_ext}2.fastq.gz -outdir kallisto_pipeline_output/Filtered_BB/${name} -mah 30G -paired -bbduk_conf $pipeline/trim_adapters_quality.txt -lit ${literals}
        fi
        # give feedback about completion of BBDUK
        echo "Trimming complete. Calculating TPM for ${name}."
    fi

    # check if kallisto ouput directory exists, if not, create it
    if [ ! -d 'kallisto_pipeline_output/results' ]; then
        mkdir 'kallisto_pipeline_output/results'
    fi

    # run Kallisto (using 40 threads and 100 bootstraps) if the file hasn't be processed before
    if [ -d "kallisto_pipeline_output/results/${name}" ]
    then
        echo "Kallisto has already processed file: ${name}."
    else
        mkdir "kallisto_pipeline_output/results/${name}/"
        mkdir "kallisto_pipeline_output/results/${name}/kallisto/"
        if [ "$interleaved" == "t" ]
        then
            kallisto quant -i $index -t $threads -b 100 -o kallisto_pipeline_output/results/${name}/kallisto kallisto_pipeline_output/Filtered_BB/${name}/${name}.Filtered.R1.fastq.gz kallisto_pipeline_output/Filtered_BB/${name}/${name}.Filtered.R2.fastq.gz            
        fi

        # Check if shared TPM folder exists, if not, create it
        if [ ! -d 'kallisto_pipeline_output/all_tpm_outputs' ]; then
            mkdir 'kallisto_pipeline_output/all_tpm_outputs'
        fi

        # Rename kallisto output files with proper file names
        if [ -s "kallisto_pipeline_output/results/${name}/named_outputs/${name}_abundance.h5" ]
        then
            echo "Kallisto outputs for ${name} have already been renamed."
        else
            mkdir "kallisto_pipeline_output/results/${name}/named_outputs/"
            cp "kallisto_pipeline_output/results/${name}/kallisto/abundance.h5" "kallisto_pipeline_output/results/${name}/named_outputs/${name}_abundance.h5"
            cp "kallisto_pipeline_output/results/${name}/kallisto/abundance.tsv" "kallisto_pipeline_output/results/${name}/named_outputs/${name}_abundance.tsv"
            cp "kallisto_pipeline_output/results/${name}/kallisto/run_info.json" "kallisto_pipeline_output/results/${name}/named_outputs/${name}_run_info.json"
        fi
        # move TPM output to shared folder
        if [ -s "kallisto_pipeline_output/all_tpm_outputs/${name}_abundance.tsv" ]
        then
            echo "${name} TPM file already in merged folder."
        else
            cp "kallisto_pipeline_output/results/${name}/named_outputs/${name}_abundance.tsv" "kallisto_pipeline_output/all_tpm_outputs/"
        fi
    fi
    exit
done

        
