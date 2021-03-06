## SNP Pipeline stuff:

perl gtf2vep.pl -i ~/bdaccessions/Temp/Bdistachyon_283_v2.1.gene_exons.vep.gtf -f ~/bdaccessions/Ref/Bdistachyon_283_assembly_v2.0.fa -d 78 -s brachypodium_distachyon

## Filter out unmapped reads from bam:

samtools view -h -F 4 -b <bamfile> > <mapped_onlybam>

## Keep only properly paired reads

samtools view -f 0x2 -b <bamfile> > <properly_mapped_bam>

## RepeatMasker CLI Args In Process:
RepeatMasker -pa 16 -s -q -lib /home/clizarraga/bdRepeats/all_repeats.lib -dir /home/clizarraga/bdRepeats/ -a -html -source -gff /shares/tmockler_share/clizarraga/bdmaker/Brachypodium_distachyon.mainGenome.fasta

## RepeatMasker buildSummary Output:
## Needs work with the current hack of adding the entire lines. Maybe just extract the X-likes?
perl buildSummary.pl -species "brachypodium distachyon" -genome ~/bdRepeats/BrachyV3_names_length.tsv ~/bdRepeats/archive/quick-run/Brachypodium_distachyon.mainGenome.fasta.out > ~/bdRepeats/archive/quick-run/custom_out.tbl

## Testing
bcftools view -g hom Adi-2.raw.snps.vcf -O v -o Adi-2.raw.snps.bcftools.hom.vcf

## Filtering by quality etc.
bcftools filter -e "QUAL<500" Adi-12.raw.snps.hom.vcf | bcftools view -U -v snps -g ^miss -f "PASS" > Adi-12.vcf

## Bash for loops to fix SICER output.

## Wiggle files to proper chromosome names from chr1-5 to Bd1-5
for x in *.wig;do xsub=$(echo $x | sed -r 's/(.*)\.(.*)/\1\.proper\.\2/');sed -r 's/(chrom=)chr([12345])/\1Bd\2/' $x > $xsub & done;wait;echo "BOIII"
# Converting .wig to .bed:
for x in *.proper.wig;do wig2bed < $x > $x.bed & done;wait;echo "BOI"

## Bed files to proper chromosome names from chr1-5 to Bd1-5
for x in *.bed;do xsub=$(echo $x | sed -r 's/(.*)(bed)/\1proper\.bed/');sed -r 's/chr/Bd/' $x > $xsub & done;wait;echo "BOI"

## SICER run commands:
# Random Background
sh SICER-rb.sh ~/Encode/Sarit_Reads/ChIP_2015-07-21/filtered/Beds/masked/ ChIP_12_AC-9_0.4_masked_Aligned.out.chr.bed Output/masked/AC-9/0.4/ bdist 1 200 101 0.95 400 100
sh SICER-rb.sh ~/Encode/Sarit_Reads/ChIP_2015-07-21/filtered/Beds/masked/ ChIP_12_AC-9_0.4_masked_Aligned.out.chr.bed Output/masked/AC-9/0.4/ bdist 1 200 240 0.95 400 100
# Estimating fragment sizes
sh fragment-size-estimation.sh ~/Encode/Sarit_Reads/ChIP_2015-07-21/filtered/Beds/ChIP_10_Kit_AC-9_0.2_Aligned.out.bam.chr.bed chr1 75071545

## Convert sam/bam files in several folders under parent to bed using the original name.
for sam in */*.sam;do dir=$(echo $sam | cut -d'/' -f1);fname=$(echo $sam | cut -d'/' -f2 | cut -d'.' -f1-6).am;convert2bed -i sam -m 12G < $sam > $dir/$fname;done
