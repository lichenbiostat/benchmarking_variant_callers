#!/bin/bash
set -o nounset
#set -o errexit
 
#########################################
#written by Fenglin
#2019-03-20 created
#AIM: to insert random variants to hg19 fasta file
#########################################

echo begin random_fa at: `date`

project=$1
patient=$2
sample=$3

### select random sites from regions
vcf2bed.pl ${origDir}/${sample}.sorted.vcf.gz > ${sample}.GATK.RNA.recal.var.flt.bed 
rm random_${n}_sites_conf.bed
while read line; do
    regionFile=$line;
    bedtools random -l 1 -n $n -g $genomefile >tmp.bed
    bedtools shuffle -incl $regionFile -excl ${sample}.GATK.RNA.recal.var.flt.bed -i tmp.bed -g $genomefile -noOverlapping >>random_${n}_sites_conf.bed
done <$regionlist

### convert bed to vcf format
Rscript bed2vcf.R $outDir/random_${n}_sites_conf $reffasta
vcfAddAlt.pl random_${n}_sites_conf.vcf > tmp && mv tmp random_${n}_sites_conf.vcf

## generate simulated fasta file from random vcf
java -jar path_to_gatk/GenomeAnalysisTK.jar -T FastaAlternateReferenceMaker -o random_${n}_sites_conf.fa -R $reffasta --variant random_${n}_sites_conf.vcf
sed -i 's/>.*chr/>chr/g; s/>.*ERCC/>ERCC/g; s/:1//g' random_${n}_sites_conf.fa # change format
samtools faidx random_${n}_sites_conf.fa
rm "random_${n}_sites_conf.dict"
$path_to_picard/CreateSequenceDictionary.jar R= "random_${n}_sites_conf.fa" O="random_${n}_sites_conf.dict"

echo end random_fa at: `date`
