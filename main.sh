# Create required directories
mkdir -p ./annotated_VCF_files
mkdir -p ./filtered_VCF_files
mkdir -p ./mutations_per_gene
mkdir -p ./compressed_files
mkdir -p ./combined_vcf_per_sample/heat_shock
mkdir -p ./combined_vcf_per_sample/cold_shock

# Step 1: Annotate and Filter Each VCF (Before Merging)
for file in *.vcf; do
    # Annotate using SnpEff
    snpEff -v DQ657948_1 "$file" > ./annotated_VCF_files/"${file%.vcf}_annotated.vcf"

    # Filter annotated VCF by allele frequency (AF >= 0.9)
    bcftools filter -i 'INFO/AF >= 0.9' ./annotated_VCF_files/"${file%.vcf}_annotated.vcf" \
        -o ./filtered_VCF_files/"${file%.vcf}_filtered.vcf"

    # Compress and index filtered VCF
    bgzip ./filtered_VCF_files/"${file%.vcf}_filtered.vcf"
    tabix -p vcf ./filtered_VCF_files/"${file%.vcf}_filtered.vcf.gz"

    # Move compressed files
    mv ./filtered_VCF_files/"${file%.vcf}_filtered.vcf.gz" ./compressed_files/
    mv ./filtered_VCF_files/"${file%.vcf}_filtered.vcf.gz.tbi" ./compressed_files/
done

# Step 2: Merge SNP and SV VCFs Per Sample (Using Filtered, Annotated Files)
for sample in {1..5}; do
    bcftools merge ./compressed_files/P15-"$sample".trimed1000.snp_filtered.vcf.gz \
                   ./compressed_files/P15-"$sample".trimed1000.sv_sniffles_filtered.vcf.gz \
                   -o ./combined_vcf_per_sample/heat_shock/P15-"$sample".combined.vcf
done

for sample in {6..10}; do
    bcftools merge ./compressed_files/P15-"$sample".trimed1000.snp_filtered.vcf.gz \
                   ./compressed_files/P15-"$sample".trimed1000.sv_sniffles_filtered.vcf.gz \
                   -o ./combined_vcf_per_sample/cold_shock/P15-"$sample".combined.vcf
done

# Step 3: Extract Mutations Per Gene from Merged VCFs
for file in ./combined_vcf_per_sample/heat_shock/*.vcf ./combined_vcf_per_sample/cold_shock/*.vcf; do
    bcftools query -f '%CHROM\t%POS\t%INFO/ANN\n' "$file" \
        | cut -d'|' -f4 | sort | uniq -c | sort -nr > ./mutations_per_gene/"$(basename "${file%.vcf}")_mutations_per_gene.txt"
done