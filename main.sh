for file in *.vcf; do

  mkdir ./annotated_VCF_files
  snpEff -v DQ657948_1 "$file" > ./annotated_VCF_files/"${file%.vcf}_annotated.vcf"

  mkdir ./filtered_VCF_files
  bcftools filter -i 'INFO/AF >= 0.9' ./annotated_VCF_files/"${file%.vcf}_annotated.vcf" -o ./filtered_VCF_files/"${file%.vcf}_filtered.vcf"

  mkdir ./mutations_per_gene
  bcftools query -f '%CHROM\t%POS\t%INFO/ANN\n' ./filtered_VCF_files/"${file%.vcf}_filtered.vcf" | cut -d'|' -f4 | sort | uniq -c | sort -nr > ./mutations_per_gene/"${file%.vcf}_mutations_per_gene.txt"
done

# Create directories for combined VCFs and compressed files
mkdir -p ./combined_vcf_per_sample/heat_shock
mkdir -p ./combined_vcf_per_sample/cold_shock
mkdir -p ./compressed_files

# Compress and index all VCF files
for file in *.vcf; do
    bgzip "$file"                          # Compress the file in place
    tabix -p vcf "$file.gz"                # Index the compressed VCF
    mv "$file.gz" ./compressed_files/      # Move the compressed file to compressed_files
    mv "$file.gz.tbi" ./compressed_files/  # Move the index file to compressed_files
done

# Merge SNP and SV VCFs for each sample (heat & cold shock)
for file_number_heat in {1..5}; do
    bcftools merge ./compressed_files/P15-"$file_number_heat".trimed1000.snp.vcf.gz \
                   ./compressed_files/P15-"$file_number_heat".trimed1000.sv_sniffles.vcf.gz \
                   -o ./combined_vcf_per_sample/heat_shock/P15-"$file_number_heat".combined.vcf
done

for file_number_cold in {6..10}; do
    bcftools merge ./compressed_files/P15-"$file_number_cold".trimed1000.snp.vcf.gz \
                   ./compressed_files/P15-"$file_number_cold".trimed1000.sv_sniffles.vcf.gz \
                   -o ./combined_vcf_per_sample/cold_shock/P15-"$file_number_cold".combined.vcf
done