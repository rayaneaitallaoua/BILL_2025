#!/bin/bash

# Create required directories for organizing files
mkdir -p ./compressed_files/compressed_sv
mkdir -p ./compressed_files/compressed_snp
mkdir -p ./combined_vcfs/snp
mkdir -p ./combined_vcfs/sv

# Define a spinner for visual feedback during compression
SPINNER=('|' '/' '-' '\')
count=0

echo "Step 1: Compressing VCFs..."
# Loop through all VCF files in the current directory
for file in *.vcf; do
    # Display rotating spinner
    count=$(( (count + 1) % 4 ))
    echo -ne "\rCompressing: ${SPINNER[$count]}"

    # Compress the VCF file using bgzip
    bgzip "$file"
    
    # Index the compressed VCF file using tabix
    tabix -p vcf "${file}.gz"

    # Move compressed files based on variant type
    if [[ $file == *"snp"*.vcf ]]; then
        mv "${file}.gz" "${file}.gz.tbi" ./compressed_files/compressed_snp/
    elif [[ $file == *"sv"*.vcf ]]; then
        mv "${file}.gz" "${file}.gz.tbi" ./compressed_files/compressed_sv/
    fi
done
echo -ne "\rStep 1: Done! \n"

echo "Step 2: Merging VCFs..."

# Initialize empty strings to store file names for merging
to_merge_snp=""
to_merge_sv=""

# Concatenate SNP VCF file names into a single string
for file in ./compressed_files/compressed_snp/*.vcf.gz; do
    to_merge_snp="${to_merge_snp} $file"
done

# Concatenate SV VCF file names into a single string
for file in ./compressed_files/compressed_sv/*.vcf.gz; do
    to_merge_sv="${to_merge_sv} $file"
done

# Merge SNP VCF files if there are any
if [[ -n "$to_merge_snp" ]]; then
    bcftools merge $to_merge_snp -o ./combined_vcfs/snp/P90_snp_combined.vcf
fi

# Merge SV VCF files if there are any
if [[ -n "$to_merge_sv" ]]; then
    bcftools merge $to_merge_sv -o ./combined_vcfs/sv/P90_sv_combined.vcf
fi

echo -ne "\rStep 2: Done! \n"

echo "Step 3: Extracting AF Per SV..."
# Extract allele frequency (AF) from the merged SV VCF and count unique occurrences
bcftools query -f '%INFO/AF\n' ./combined_vcfs/sv/P90_sv_combined.vcf | sort | uniq -c > "AF_per_SV.txt"
echo -ne "\rStep 3: Done! \n"

echo "Step 4: Extracting GQ Per SNP..."
# Extract genotype quality (GQ) from the merged SNP VCF and count unique occurrences
bcftools query -f '%QUAL\n' ./combined_vcfs/snp/P90_snp_combined.vcf | sort | uniq -c > "AF_per_SNP.txt"
echo -ne "\rStep 4: Done! \n"

echo "All steps completed successfully!"