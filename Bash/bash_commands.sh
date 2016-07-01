## Find line number of match:
sed -n '/pattern/=' filename

## Pair with grep for specific occurrence of match within file:
grep "overall pattern" filename | sed -n '/specific pattern/='

## Check if directories are different:
diff <(ls -laR <firstdirectory/> | awk '{print $9}' ) <(ls -laR <seconddirectory/> | awk '{print $9}')

## Sort unix file ignore header (if 1 line, if header>1 line increment numbers after n by however many header lines there are)
(head -n1 <file> && tail -n +2 <file> | sort) > <outfile>

## Sort gtf/gff file by first column, then second column numeric and stable sort.:
## sort -s -k1,1 -k4,4n Brachypodium_distachyon.mainGenome.hq.gtf > Brachypodium_distachyon.mainGenome.sort.hq.gtf
sort -s[stable] -k1,1[first column] -k4,4n[fourth column, numeric] <filein> > <fileout>

## Epic Bash Script to change dummy sample name of vcf files using filename first delimiter.
for x in *.raw.snps.hom.vcf; do xsub=$(echo $x | cut -d. -f1);sed -i -r "s/(#CHROM.*)JGI/\1$xsub/" $x;done

## Bgzipping and indexing vcf files for bcftools merge (might be useful for other bgzip index needing files)
for x in *.vcf; do bgzip -c $x > $x.gz && tabix $x.gz;done

## File types and listing in directories.
## List all file extensions lower or uppercase AND count the amount of files that exist.
find . -type f -name "*.*" | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]' | sort | uniq -c
## List all distinct file extensions.
find . -type f -name "*.*" | sed 's/.*\.//' | sort -u

## Replace word in all files in directory.
sed -i -- 's/xrange/range/g' *

## Find all files with shebang in first line.
## find . -type f -exec awk '/^#!.*bash/{print FILENAME} {nextfile}' {} +
find . -type f -exec awk '/^#!.*<program>/{print FILENAME} {nextfile}' {} +

# Remove all files and folders in a directory owned by user
# I used it for /tmp/ probably, bad to use in any other circumstance.
directory=/tmp/
user=clizarraga
rm -rf `ls -la $directory | grep $user | awk -v dir="$directory" '{print dir$9}'`

# Search SnapshotInfo.csv for zoom levels and sort and only print uniques
grep "VIS" SnapshotInfo.csv | grep -Po "_z[0-9]+_" | sort | uniq
