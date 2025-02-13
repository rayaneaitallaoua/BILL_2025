if [ $# -lt 1 ]; then
    echo "Entrer un nom de dossier à analyser en argument.\n"
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
# Crée le nouveau dossier avec _output
nouveau_dossier="${dossier}_output"

# Crée le nouveau dossier
    
mkdir -p "$nouveau_dossier"
echo "Création du dossier: $nouveau_dossier"
mkdir -p ./$nouveau_dossier/filtered_vcfs

# Parcourir tous les fichiers .sv_sniffles.vcf du dossier
for file in "$dossier"/*.sv_sniffles.vcf; do
    filename=$(basename "$file")
    new_file=./$nouveau_dossier/${filename%.sv_sniffles.vcf}_filtered.vcf
    
    # Filtrer le VCF
    bcftools filter -i "INFO/AF >= 0.05" "$file" -o "$new_file"
    
    # Déplacer le fichier
    mv "$new_file" ./$nouveau_dossier/filtered_vcfs
    
    #Compter les variants et ajouter au total
    current_count=$(grep -vc "^#" "./$nouveau_dossier/filtered_vcfs/$(basename "$new_file")")
    ((variant_number+=current_count))
    new_file=$(basename "$new_file")
    new_file=$(echo "$new_file" | cut -d '.' -f1)

    echo "$new_file,$current_count" >> count.csv

done

#for file in "$nouveau_dossier"/filtered_vcfs/*.vcf;do
 #   filename=$(basename "$file")
  #  filename=${filename%.trimed1000_filtered.vcf}
   # num_exp=$(echo "$filename" | cut -d '-' -f 2)
    #if (($num_exp <= 5)); then
#done

