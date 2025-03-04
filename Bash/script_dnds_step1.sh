#!/bin/bash

################################## OBJECTIFS #######################################################
#Je veux convertir mes fichiers VCF en sequences FASTA pour pouvoir ensuite calculer le dnds
#donc creation de sequences complètes qui intègrent les mutations par rapport a la sequence de reference

#il faut télécharger la séquence du génome de référence en format fasta à partir de genbank 
#il n'y en a pas besoin dans ce script mais dans le script R par la suite

#Ce script doit être rangé dans le dossier qui contient les dossiers vcf pour chaque génération 
#(là où on fait tourner le script stats.sh)
#les fichiers de sortis ne seront pas ranges au meme endroit

####################################################################################################
#On va chercher le dossier qui nous intéresse
if [ $# -lt 1 ]; then
    echo "Entrer un nom de dossier a analyser en argument.\n"
    exit 1
fi

dossier="$1"


# Vérifier si le fichier existe
if [ ! -d "$dossier" ]; then
    echo "Le dossier '$dossier' n'existe pas."
    continue
fi

# Enlève le slash final du nom du dossier
dossier=${dossier%/}

INPUT_DIR="/home/chemindacces/BILL/2025-BILL/$dossier/vcf_output/filtered_snp"
OUTPUT_DIR="/home/chemindacces/BILL/Groupe3/Test/SNP_ann_filter_script-stats/$dossier" #${dossier}_fasta
mkdir -p "$OUTPUT_DIR"


DIR_COMPRESS_INDEX="$OUTPUT_DIR/compressed_index_files"
DIR_FASTA="$OUTPUT_DIR/fasta_files"

mkdir -p "$DIR_COMPRESS_INDEX"
mkdir -p "$DIR_FASTA"


echo "Création du dossier:"
echo " - $dossier"
echo " - $DIR_COMPRESS_INDEX"
echo " - $DIR_FASTA"


find "$INPUT_DIR" -type f -name "*.vcf" | while read -r file ; do
    base_name=$(basename "${file%.vcf}") # % : enlever le .vcf pour n'avoir que le nom du fichier
    
    #on copie colle les dossiers vcf dans le dossier dans lequel on veut compresser et indexer
    cp "$file" "$DIR_COMPRESS_INDEX/${base_name}.vcf"

    # Compress and index filtered VCF
    bgzip "$DIR_COMPRESS_INDEX/${base_name}.vcf"
    tabix -p vcf "$DIR_COMPRESS_INDEX/${base_name}.vcf.gz"

done

find "$DIR_COMPRESS_INDEX" -type f -name "*.vcf.gz" | while read -r file ; do
    base_name=$(basename "${file%.vcf}")
    
    bcftools query -f "%POS\t%ALT" "$file" > "${DIR_FASTA}/${base_name}.fasta" # extrait que l'allèle alternatif

done