#!/bin/bash


##################### Facultatif ################
#(j'ai eu un pb à un moment et j'ai pensé qu'il y avait peut être 
#des lignes vides dans mes fichiers fasta)

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

#Dossier contenant les fichiers fasta
INPUT_DIR="$(pwd)/$dossier/fasta_files/post_R_treatment"

find "$INPUT_DIR" -type f -name "*.fasta" | while read file; do

    #Vérifie si la dernière ligne est vide
    if [[ -z $(tail -n 1 "$file") ]]; then
        #supprimer la dernière ligne vide
        sed -i '${/^$/d;}' "$file"
        #supprimer uniquement le dernier retour à la ligne en trop
        truncate -s -1 "$file"
        echo "Dernière ligne vide supprimée : $file"
    fi
done
echo "tous les fichiers FASTA ont été nettoyés"

#supprimer les lignes vides
#sed -i '/^$/d' "$file"
#sed -i ':a;/^[[:space:]]*$/{$d;N;ba}' "$file"

#supprimer les lignes vides et les espaces vides
#sed -i '$/^$/d' -e 's/[[:space:]]*$//' "$file"