## Making a gtf vep friendly the old way, renaming the type to ALL PROTEIN_CODING. DO NOT USE AGAIN
awk 'BEGIN { FS="\t"; OFS = FS};{print $1,"protein_coding",$3,$4,$5,$6,$7,$8,$9}' Bdistachyon_283_v2.1.gene_exons.gtf > Bdistachyon_283_v2.1.gene_exons.vep.gtf

## Removing the Bd from all the chromosomes and just making them 1-5. Easier way to do it now I think.
awk 'BEGIN {FS = OFS = "\t" };$1 ~ /^[0-9]/ { $1 = "Bd"$1 };{print $1,$2,$3,$4,$5,$6,$7,$8,$9}' Bdistachyon_283_v2.1.gene_exons.vep.gtf > Bdistachyon_283_v2.1.gene_exons.vep.1.gtf

# Removing all lines that have X in column 5. Don't remember why I made this.
awk 'BEGIN {FS=OFS="\t"};$5 ~ /[^X]/ { print $0}' Koz-3.Alignments.raw.vcf > Koz-3.Alignments.NotX.raw.vcf

## Greatest Number in Column 6 starting at row 36:
sed -n '36~1p' <file> | awk 'BEGIN {FS=OFS="\t"}; a <= $6 {a=$6} END{print a}'

## Mean in Column 6 starting at row 36:
sed -n '36~1p' <file> | awk 'BEGIN {FS=OFS="\t"}; {a+=$6} END{print a/NR}'

## Match pattern in CLI:
## ary is array here.
## gawk 'match($0, /Name=(Bradi[0-9]g[0-9][0-9][0-9][0-9][0-9])/,ary) {print ary[1]}'
gawk 'match($0, /<pattern/,ary) {print ary[1]}'

## Pull out pattern from gff3:
## awk 'BEGIN {FS=OFS="\t"}; $9 ~ "Bradi5g" {print $0}' Bd5.genes.gff > Bd5.Bradi5.genes.gff
awk 'BEGIN {FS=OFS="\t"}; $9 ~ <pattern> {print $0}' <file> > <outfile>

## Select lines between two patterns including start pattern:
## awk '/>Bd5/ {flag=1}/>scaffold_12/{flag=0} flag' Brachypodium_distachyon.mainGenome.fasta > ~/bdmaker/Bdistachyon_v3.Bd5.fasta
awk '/START/ {flag=1}/END/{flag=0} flag' file > outfile

## Concatenate files if they all have the same header:
## All headers are one line headers.
awk 'FNR==1 && NR!=1 { while (/^<header>/) getline; } 1 {print} ' file*.txt > all.txt

## Prepend to column and print all other lines as well:
awk 'BEGIN {FS=OFS="\t"} $<column>~/<regex>/ {$<column>="<string>"$<column>} {print $0}' <in> > <out>

## Count fasta sequence lengths in a fasta file:
## I also have a python BioPython seq_lengths.py that does this.
awk '/^>/ {if (seqlen){print seqlen}; print ;seqlen=0;next; } { seqlen = seqlen +length($0)}END{print seqlen}' file.fa
## Tab separated file (identical to seq_length.py)
awk '/^>/ {if (seqlen){print seqlen}; printf substr($0,2);printf "\t";seqlen=0;next; } { seqlen = seqlen + length($0)}END{print seqlen}' file.fa

## Remove all features of a length longer than actual chromosome length:
awk -F'\t' '{FS=OFS="\t"} !($1 == "Bd3" && $5 > 59640145) && !($1 == "Bd2" && $5 > 59130575) && !($1 == "Bd4" && $5 > 48594894) && !($1 == "Bd5" && $5 > 28630136) {print}' Brachypodium_distachyon.mainGenome.all.vep.fixed.gtf > temp.gtf

## Get n first fasta sequences
awk -v RS=">" 'NR>1 {gsub("\n", ";", $0); sub(";$", "", $0); print ">"$0}' contigs.fa | head -n20 | tr ';' '\n' > top20_contigs.fa
