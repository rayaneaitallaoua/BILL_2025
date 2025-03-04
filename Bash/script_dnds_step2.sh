#!/bin/bash

############################################### Arborescence des dossiers ##########################################################################
#On a les fichiers VCF annotes grâce au script stats.sh
#on cree des fichiers "fasta" qui n'en sont pas avec le script "script_dnds_step1.sh"
#les fichiers de ce script  normalement ete rangés dans un nouveau repertoire (OUTPUT) : 
#       .../new_repertoire/P90/compressed_index_file
#       .../new_repertoire/P90/fasta_file
#Dans le dossier "fasta_file", j'ai mis les fichiés.fasta générés par "script_dnds_step1.sh"
#Ensuite il faut faire tourner le script R : "fasta_file_preparation_dnds"
#Ce script fabrique des fichiers fasta "propres" pour chaque ORF de chaque echantillon de P90
#Il génère 97 sous-dossiers, 1 par ORF qui contiennent chacun 11 fichiers fasta : 1 pour le génome de référence qui correspond à l'ORF et 10 pour les échantillons
#sur le github le script "fasta_file_preparation_dnds" créer ces 97 sous dossiers sont créés dans le dossier \github\BILL_2025\R\resultats_fasta_files 
#le dossier "resultats_fasta_files" est copié collé dans le dossier .../new_repertoire/P90/fasta_file (et je l'ai renommé "post_R_traitment")

#Ce script là doit tourner dans .../repertoire/
#il va chercher le dossier .../repertoire/P90/fasta_files/post_R_traitment ; il boucle dans ce dossier : parcours chaque sous-dossier et les fichiers contenus
#Sauf pour les dossiers qui s'appellent ORF_33, ORF_40, ORF_41, ORF_64
#Ce script créer des nouveaux fichiers fasta (qui combienent la séquence du génome de référence avec celle de chaque variant par ORF) 
#Ces fichiers fasta combinés seront envoyés dans un nouveau dossiers "combined"
#le dossier "combined" se trouve dans .../repertoire/P90/fasta_files

#Donc à l'issu du script fasta_file contient les dossiers Combined et post_R_traitment avec les fichiers.fasta générés par le script dnds step1
##########################################################################################################################################################


if [$# -lt 1 ]; then
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
#le dossier à appeler c'est P90 mais il peut y en avoir d'autres...

#Dossier contenant les fichiers fasta
INPUT_DIR="$(pwd)/$dossier/fasta_files/post_R_treatment"
OUTPUT_DIR="$(pwd)/$dossier/fasta_files/combined"
mkdir -p "$OUTPUT_DIR"

#Dossiers à éviter
DIR_A_EVITER=("ORF_33" "ORF_40" "ORF_41" "ORF_64")

# Activer l'option nullglob et failglob pour gérer les globs vides et les erreurs plus explicites
shopt -s nullglob
#shopt -s failglob

# boucle sur chaque dossier ORF
for ORF_DIR in "$INPUT_DIR"/*/ ; do
    #ORF_DIR_NAME=${ORF_DIR%/}
    ORF_DIR_NAME=$(basename "$ORF_DIR")


    if [[ " $DIR_A_EVITER " =~ " $ORF_DIR_NAME " ]]; then
        echo "Ignorer $ORF_DIR_NAME"
        continue
    fi
    #else

    for SAMPLE_FILE in "$ORF_DIR"*.fasta; do
        echo "SAMPLE_FILE :  $SAMPLE_FILE"

        #vérifie si le fichier de référence existe
        REF_FILE=(${ORF_DIR}/*_gen_ref.fasta) #c'est le globs qui fait qu'on peut ecrire comme ça?
        #if [ ! -f "$REF_FILE" ]
        if [ ${#REF_FILE[@]} -ne 1 ]; then
            echo "ERREUR : Nombre de fichiers de référence incorrect dans $ORF_DIR"
            echo "Nombre de fichiers trouvés : ${#REF_FILES[@]}"
            continue
        fi

        echo "REF_FILE = $REF_FILE"

        if [[ "$SAMPLE_FILE" != "$REF_FILE" ]] ; then
            #nom de l'echantillon
            SAMPLE_NAME=$(basename "$SAMPLE_FILE" .fasta)

            #creer le fichier combiné 
            COMBINED_FILE="${OUTPUT_DIR}/${SAMPLE_NAME}_combined.fasta"

            cat "$REF_FILE" <(echo) "$SAMPLE_FILE" > "$COMBINED_FILE"

            echo "fichier créé : $COMBINED_FILE"
        fi
    done
    #fi
done
# Désactiver nullglob
shopt -u nullglob

echo "Traitement terminé."
