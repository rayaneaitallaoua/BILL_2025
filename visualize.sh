#!/bin/bash

# Create required directories
mkdir -p ./compressed_files
mkdir -p ./compressed_files/compressed_sv
mkdir -p ./compressed_files/compressed_snp
mkdir -p ./combined_vcfs
mkdir -p ./combined_vcfs/snp
mkdir -p ./combined_vcfs/sv

# Define spinner
SPINNER=('|' '/' '-' '\')
count=0

echo "Step 1: Compressing VCFs..."
for file in *.vcf; do
    # Display rotating spinner
    count=$(( (count + 1) % 4 ))
    echo -ne "\rCompressing: ${SPINNER[$count]}"

    # Compress and index filtered VCF
    bgzip "$file"
    tabix -p vcf "$file"

    # Move compressed files per variant type
    if [[ $file == *"snp"*.gz || $file == *"snp"*.tbi ]]; then

        mv "$file" ./compressed_files/compressed_snp

    elif [[ $file == *"sv"*.gz || $file == *"sv"*.tbi ]]; then

        mv "$file" ./compressed_files/compressed_sv

    fi
    

done
echo -ne "\rStep 1: Done! \n"

echo "Step 2: Merging VCFs..."

to_merge_snp = ""
to_merge_sv = ""

for file in ./compressed_files/compressed_snp; do
    to_merge_snp = "${to_merge_snp} $file"
done
    
bcftools merge $to_merge_snp -o ./combined_vcfs/snp/P90_snp_combined.vcf

for file in ./compressed_files/compressed_sv; do
    to_merge_sv = "${to_merge_sv} $file"
done
    
bcftools merge $to_merge_sv -o ./combined_vcfs/snp/P90_sv_combined.vcf

echo -ne "\rStep 2: Done! \n"

echo "Step 3: Extracting AF Per SV..."

    bcftools query -f '%INFO/AF\n' ./combined_vcfs/sv/P90_sv_combined.vcf \
        | cut -d'=' -f1 | uniq -c > "AF_per_SV.txt"

echo -ne "\rStep 3: Done! \n"

echo "Step 4: Extracting GQ Per SNP..."

    bcftools query -f '%QUAL\n' ./combined_vcfs/snp/P90_snp_combined.vcf \
        | cut -d'=' -f1 | uniq -c > "AF_per_SNP.txt"

echo -ne "\rStep 3: Done! \n"

echo "All steps completed successfully! "