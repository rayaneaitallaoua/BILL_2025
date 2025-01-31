for file in *.vcf; do

  mkdir ./annotated_VCF_files
  snpEff -v DQ657948_1 "$file" > ./annotated_VCF_files/"${file%.vcf}_annotated.vcf"

  mkdir ./filtered_VCF_files
  bcftools filter -i 'INFO/AF >= 0.9' ./annotated_VCF_files/"${file%.vcf}_annotated.vcf" -o ./filtered_VCF_files/"${file%.vcf}_filtered.vcf"

  mkdir ./mutations_per_gene
  bcftools query -f '%CHROM\t%POS\t%INFO/ANN\n' ./filtered_VCF_files/"${file%.vcf}_filtered.vcf" | cut -d'|' -f4 | sort | uniq -c | sort -nr > ./mutations_per_gene/"${file%.vcf}_mutations_per_gene.txt"
done