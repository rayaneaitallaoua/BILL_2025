#!/bin/bash

# Create required directories
mkdir -p ./compressed_files
mkdir -p ./compressed_files/compressed_sv
mkdir -p ./compressed_files/compressed_snp
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
    if [[ $file == *"snp"*.gz ]]; then

        mv "$file" ./compressed_files/compressed_snp

    elif [[ $file == *"sv_sniffles"*.gz ]]; then

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

echo "Step 3: Extracting AF Per Gene..."
for file in ./combined_vcf_per_sample/heat_shock/*.vcf ./combined_vcf_per_sample/cold_shock/*.vcf; do
    count=$(( (count + 1) % 4 ))
    echo -ne "\rExtracting: ${SPINNER[$count]}"

    bcftools query -f '%CHROM\t%POS\t%INFO/ANN\n' "$file" \
        | cut -d'|' -f4 | uniq -c > ./mutations_per_gene/"$(basename "${file%.vcf}")_mutations_per_gene.txt"
done
echo -ne "\rStep 3: Done! \n"

echo "Step 4: Counting Mutation Types..."
for file in ./combined_vcf_per_sample/heat_shock/*.vcf ./combined_vcf_per_sample/cold_shock/*.vcf; do
    count=$(( (count + 1) % 4 ))
    echo -ne "\rCounting: ${SPINNER[$count]}"

    bcftools query -f '%REF\t%ALT\t%INFO/SVTYPE\n' "$file" | awk '
    {
        if (length($1) == 1 && length($2) == 1) 
            print "SNP"; 
        else if ($3 != ".") 
            print $3; 
        else if (length($1) < length($2)) 
            print "Ins"; 
        else if (length($1) > length($2)) 
            print "Del";
    }' | sort | uniq -c | sort -nr > ./mutation_types/"$(basename "${file%.vcf}")_mutation_types.txt"
done
echo -ne "\rStep 4: Done! \n"

echo "All steps completed successfully! "