#Repertoire contenant les fichiers vcf (peut etre modifie selon le besoin)
INPUT_DIR="/students/BILL/2025-BILL"
OUTPUT_DIR="/students/BILL/2025-BILL/Groupe3/Test"

mkdir -p "$OUTPUT_DIR"

# Create required directories
mkdir -p "$OUTPUT_DIR/annotated_VCF_files"
mkdir -p "$OUTPUT_DIR/filtered_VCF_files"
mkdir -p "$OUTPUT_DIR/mutations_per_gene"
mkdir -p "$OUTPUT_DIR/compressed_files"
mkdir -p "$OUTPUT_DIR/combined_vcf_per_sample/heat_shock"
mkdir -p "$OUTPUT_DIR/combined_vcf_per_sample/cold_shock"
mkdir -p "$OUTPUT_DIR/mutation_types"

# Define spinner
SPINNER=('|' '/' '-' '\')
count=0


## Premiere etape : Annotation et filtrage des VCF
echo "Step 1: Annotating & Filtering VCFs..."


# Annotation : 
#Parcourir chaque generation (= dossiers differents)
for P in P15 P30 P50 P65 P90; do 

    if [[ $P == "P15" || $P == "P30" || $P == "P50" ]]; then
        #donc tous les dossiers sauf le P65 parce que celui est mal range

        #Aller dans le sous dossier KHV-U uniquement
        KHV_U_dir="$INPUT_DIR/$P/KHV-U"
        # Verifie que le dossier KHV-U existe
        if [ ! -d "$KHV_U_dir" ]; then
            echo "Le dossier $KHV_U_dir n'existe pas, passage a la generation suivante."
            continue
        fi

        # Boucle a travers tous les fichiers .vcf dans les sous-dossiers
        find "$KHV_U_dir" -type f -name "*.vcf" | while read -r file; do
            
            # Display rotating spinner
            count=$(( (count + 1) % 4 ))
            echo -ne "\rAnnotating & filtering for ${P} : ${SPINNER[$count]}"

            base_name=$(basename "${file%.vcf}") # % : enlever le .vcf pour n'avoir que le nom du fichier

            # Annotate using SnpEff
            snpEff DQ657948_1 "$file" > "$OUTPUT_DIR/annotated_VCF_files/${base_name}_annotated.vcf"
                
            #boucle if pour verifier les erreurs apres les commandes
            if [ $? -ne 0 ]; then
                echo "Erreur lors de l'annotation de $file"
                exit 1
            fi  
        done
           
    elif [[ $P == "P65_new" || $P == "P90"]]; then

        #Trouver les fichiers vcf qui sont range bizarrement : 
        P65_VCF_DIR="$INPUT_DIR/$P/vcf"
        
        # Verifie que le dossier P65_VCF_DIR existe
        if [ ! -d "$P65_VCF_DIR" ]; thlsen
            echo "Le dossier $P65_VCF_DIR n'existe pas, passage a la generation suivante."
            continue
        fi

        find "$P65_VCF_DIR" -type f -name "*.vcf" | while read -r file; do
            
            # Display rotating spinner
            count=$(( (count + 1) % 4 ))
            echo -ne "\rAnnotating & filtering for ${P} : ${SPINNER[$count]}"

            base_name=$(basename "${file%.vcf}") # % : enlever le .vcf pour n'avoir que le nom du fichier

            # Annotate using SnpEff
            snpEff DQ657948_1 "$file" > "$OUTPUT_DIR/annotated_VCF_files/${base_name}_annotated.vcf"
                
            #boucle if pour verifier les erreurs apres les commandes
            if [ $? -ne 0 ]; then
                echo "Erreur lors de l'annotation de $file"
                exit 1
            fi  

        done  

    else 
        echo "Etape 1 : Il y a un probleme dans les dossiers..."
    fi

done

#Filtrage, compressage et indexation
find "$OUTPUT_DIR/annotated_VCF_files" -type f -name "*.vcf" | while read -r file; do 
    
    base_name=$(basename "${file%.vcf}")

    # Filter annotated VCF by allele frequency (AF >= 0.9)
    bcftools filter -i 'INFO/AF >= 0.9' "$file" -o "$OUTPUT_DIR/filtered_VCF_files/${base_name}_filtered.vcf"

    # Compress and index filtered VCF
    bgzip "$OUTPUT_DIR/filtered_VCF_files/${base_name}_filtered.vcf"
    tabix -p vcf "$OUTPUT_DIR/filtered_VCF_files/${base_name}_filtered.vcf.gz"

    # Move compressed files
    mv "$OUTPUT_DIR/filtered_VCF_files/${base_name}_filtered.vcf.gz" "$OUTPUT_DIR/compressed_files/"
    mv "$OUTPUT_DIR/filtered_VCF_files/${base_name}_filtered.vcf.gz.tbi" "$OUTPUT_DIR/compressed_files/"

done

echo -ne "\rStep 1: Done! \n"

## Etape 2 : Fusion des VCF
echo "Step 2: Merging VCFs..."

#Fusion des fichiers pour chaque echantillon de chaque generation
for P in P15 P30 P50 P65 P90; do

    if [[ $P == "P15" ]] ; then
        for SAMPLE in {1..10}; do
            SNP_FILE="$OUTPUT_DIR/compressed_files/${P}-${SAMPLE}*snp_filtered.vcf.gz.tbi"
            SV_FILE="$OUTPUT_DIR/compressed_files/${P}-${SAMPLE}*sv_filtered.vcf.gz.tbi"
            MERGE_DIR="$OUTPUT_DIR/combined_vcf_per_sample"

            mkdir -p "$MERGE_DIR"

            #Pour utiliser bcftools on le fait uniquement si les deux fichiers a fusionner sont presents dans le dossier
            #sinon ca pourrait generer des erreurs
            if [[ -f $SNP_FILE && -f $SV_FILE ]]; then
                #spinner
                count=$(( (count + 1) % 4 ))
                echo -ne "\rMerging ${P}-${SAMPLE}: ${SPINNER[$count]}"

                bcftools merge "$SNP_FILE" "$SV_FILE" -o "$MERGE_DIR/${P}-${SAMPLE}_combined.vcf"
            else
                echo "Fichiers manquants pour $P-$SAMPLE, fusion ignoree."
            fi
            
        done

    elif [[ $P == "P30" || $P == "P50" || $P == "P65" || $P == "P90" ]] ; do
        for SAMPLE_COLD in {1..5}; do
            SNP_FILE="$OUTPUT_DIR/compressed_files/${P}-${SAMPLE_COLD}*snp_filtered.vcf.gz.tbi"
            SV_FILE="$OUTPUT_DIR/compressed_files/${P}-${SAMPLE_COLD}*sv_filtered.vcf.gz.tbi"
            MERGE_DIR="$OUTPUT_DIR/combined_vcf_per_sample/cold_shock"
            mkdir -p "$MERGE_DIR"

            #Pour utiliser bcftools on le fait uniquement si les deux fichiers a fusionner sont presents dans le dossier
            #sinon ca pourrait generer des erreurs
            if [[ -f $SNP_FILE && -f $SV_FILE ]]; then
                count=$(( (count + 1) % 4 ))
                echo -ne "\rMerging ${P}-${SAMPLE_COLD}: ${SPINNER[$count]}"

                bcftools merge "$SNP_FILE" "$SV_FILE" -o "$MERGE_DIR/${P}-${SAMPLE_COLD}_combined.vcf"
            else
                echo "Fichiers manquants pour $P-$SAMPLE_COLD, fusion ignoree."
            fi

        done

        for SAMPLE_HEAT in {6..10}; do        
            SNP_FILE="$OUTPUT_DIR/compressed_files/${P}-${SAMPLE_HEAT}*snp_filtered.vcf.gz.tbi"
            SV_FILE="$OUTPUT_DIR/compressed_files/${P}-${SAMPLE_HEAT}*sv_filtered.vcf.gz.tbi"
            MERGE_DIR="$OUTPUT_DIR/combined_vcf_per_sample/heat_shock"
            mkdir -p "$MERGE_DIR"

           #Pour utiliser bcftools on le fait uniquement si les deux fichiers a fusionner sont presents dans le dossier
            #sinon ca pourrait generer des erreurs
            if [[ -f $SNP_FILE && -f $SV_FILE ]]; then
                count=$(( (count + 1) % 4 ))
                echo -ne "\rMerging ${P}-${SAMPLE_HEAT}: ${SPINNER[$count]}"

                bcftools merge "$SNP_FILE" "$SV_FILE" -o "$MERGE_DIR/${P}-${SAMPLE_HEAT}_combined.vcf"
            else
                echo "Fichiers manquants pour $P-$SAMPLE_HEAT, fusion ignoree."
            fi

        done

    else 
        echo "il y a un probleme dans les dossiers pour $P"

    fi
done

echo -ne "\rStep 2: Done! \n"

## Etape 3 : Regarder les mutations par gene
echo "Step 3: Extracting Mutations Per Gene..."
    for file in $OUTPUT_DIR/combined_vcf_per_sample/heat_shock/*.vcf $OUTPUT_DIR/combined_vcf_per_sample/cold_shock/*.vcf; do
        #Spinner
        count=$(( (count + 1) % 4 ))
        echo -ne "\rExtracting: ${SPINNER[$count]}"

        #utiliser un sort ici?
        bcftools query -f '%CHROM\t%POS\t%INFO/ANN\n' "$file" \
            | cut -d'|' -f4 | uniq -c > $OUTPUT_DIR/mutations_per_gene/"$(basename "${file%.vcf}")_mutations_per_gene.txt"
    done
    
echo -ne "\rStep 3: Done! \n"

#Etape 4 : Compter les types de mutation
echo "Step 4: Counting Mutation Types..."
    
    for file in $OUTPUT_DIR/combined_vcf_per_sample/heat_shock/*.vcf $OUTPUT_DIR/combined_vcf_per_sample/cold_shock/*.vcf; do
        #Spinner  
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
        }' | sort | uniq -c | sort -nr > $OUTPUT_DIR/mutation_types/"$(basename "${file%.vcf}")_mutation_types.txt"
    done

echo -ne "\rStep 4: Done! \n"
echo "All steps completed successfully! "