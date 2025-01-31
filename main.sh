#!/bin/bash

# Create required directories
mkdir -p ./annotated_VCF_files
mkdir -p ./filtered_VCF_files
mkdir -p ./mutations_per_gene
mkdir -p ./compressed_files
mkdir -p ./combined_vcf_per_sample/heat_shock
mkdir -p ./combined_vcf_per_sample/cold_shock
mkdir -p ./mutation_types

# Define spinner
SPINNER=('|' '/' '-' '\')
count=0

echo "Step 1: Annotating & Filtering VCFs..."
for file in *.vcf; do
    # Display rotating spinner
    count=$(( (count + 1) % 4 ))
    echo -ne "\rAnnotating & filtering: ${SPINNER[$count]}"

    # Annotate using SnpEff
    snpEff DQ657948_1 "$file" > ./annotated_VCF_files/"${file%.vcf}_annotated.vcf"

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
echo -ne "\rStep 1: Done! \n"

echo "Step 2: Merging VCFs..."
for sample in {1..5}; do
    count=$(( (count + 1) % 4 ))
    echo -ne "\rMerging: ${SPINNER[$count]}"
    
    bcftools merge ./compressed_files/P15-"$sample".trimed1000.snp_filtered.vcf.gz \
                   ./compressed_files/P15-"$sample".trimed1000.sv_sniffles_filtered.vcf.gz \
                   -o ./combined_vcf_per_sample/heat_shock/P15-"$sample".combined.vcf
done

for sample in {6..10}; do
    count=$(( (count + 1) % 4 ))
    echo -ne "\rMerging: ${SPINNER[$count]}"

    bcftools merge ./compressed_files/P15-"$sample".trimed1000.snp_filtered.vcf.gz \
                   ./compressed_files/P15-"$sample".trimed1000.sv_sniffles_filtered.vcf.gz \
                   -o ./combined_vcf_per_sample/cold_shock/P15-"$sample".combined.vcf
done
echo -ne "\rStep 2: Done! \n"

echo "Step 3: Extracting Mutations Per Gene..."
for file in ./combined_vcf_per_sample/heat_shock/*.vcf ./combined_vcf_per_sample/cold_shock/*.vcf; do
    count=$(( (count + 1) % 4 ))
    echo -ne "\rExtracting: ${SPINNER[$count]}"

    bcftools query -f '%CHROM\t%POS\t%INFO/ANN\n' "$file" \
        | cut -d'|' -f4 | awk -F'|' '!seen[$4]++ {print $4}' > ./mutations_per_gene/"$(basename "${file%.vcf}")_mutations_per_gene.txt"
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