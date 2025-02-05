#!/bin/bash

# Create required directories
mkdir -p ./compressed_files/compressed_sv
mkdir -p ./compressed_files/compressed_snp
mkdir -p ./combined_vcfs/snp
mkdir -p ./combined_vcfs/sv

echo "Step 1: Compressing and Indexing VCFs..."

# Loop through all VCF files and process them
for file in *.vcf; do
    echo "Compressing: $file"
    
    # Compress and index the VCF file
    bgzip -c "$file" > "${file}.gz"
    tabix -p vcf "${file}.gz"

    # Move files based on variant type
    if [[ $file == *"snp"*.vcf ]]; then
        mv "${file}.gz" "${file}.gz.tbi" ./compressed_files/compressed_snp/
    elif [[ $file == *"sv"*.vcf ]]; then
        mv "${file}.gz" "${file}.gz.tbi" ./compressed_files/compressed_sv/
    fi
done
echo "Step 1: Done!"

echo "Step 2: Creating file lists for merging..."

# Generate file lists
ls ./compressed_files/compressed_snp/*.vcf.gz > snp_list.txt
ls ./compressed_files/compressed_sv/*.vcf.gz > sv_list.txt


echo "Step 3: Merging VCFs..."

# Merge SNP VCFs if there are files
if [[ -s snp_list.txt ]]; then
    bcftools merge --force-samples --file-list snp_list.txt -Oz -o ./combined_vcfs/snp/P90_snp_combined.vcf
fi

# Merge SV VCFs if there are files
if [[ -s sv_list.txt ]]; then
    bcftools merge --file-list sv_list.txt -Oz -o ./combined_vcfs/sv/P90_sv_combined.vcf
fi

echo "Step 3: Done!"

echo "Step 4: Extracting AF Per SV..."
# Extract allele frequency (AF) for SVs
bcftools query -f '%INFO/AF\n' ./combined_vcfs/sv/P90_sv_combined.vcf | sort | uniq -c > "AF_per_SV.txt"
echo "Step 4: Done!"

echo "Step 5: Extracting GQ Per SNP..."
# Extract genotype quality (GQ) for SNPs
bcftools query -f '%QUAL\n' ./combined_vcfs/snp/P90_snp_combined.vcf | sort | uniq -c > "GQ_per_SNP.txt"
echo "Step 5: Done!"

echo "All steps completed successfully!"