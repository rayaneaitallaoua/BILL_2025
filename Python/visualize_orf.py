import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

file_path = "sv_with_orf.csv"
# Fonction pour compter les ORFs individuels
def count_individual_orfs(orf_series):
    orf_counts = {}
    for row in orf_series.dropna():  # Ignorer les valeurs NaN
        orfs = row.split('|')
        for orf in orfs:
            orf_counts[orf] = orf_counts.get(orf, 0) + 1
    return orf_counts
    
    # Lecture du fichier CSV
df = pd.read_csv(file_path)


# Compter les variants par ORF
orf_counts = count_individual_orfs(df['ORF'])
# Créer un DataFrame pour la visualisation
results_df = pd.DataFrame.from_dict(orf_counts, orient='index', columns=['count'])
results_df = results_df.sort_values('count', ascending=False)


# Créer la visualisation
plt.figure(figsize=(15, 8))
sns.barplot(data=results_df.reset_index(), x='index', y='count')
plt.xticks(rotation=45, ha='right')
plt.xlabel('ORF')
plt.ylabel('Nombre de variants')
plt.title('Distribution des variants par ORF')

# Ajuster la mise en page pour éviter que les labels se chevauchent
plt.tight_layout()

    
# Sauvegarder le graphique
plt.gcf().savefig('distribution_variants_orf.png', dpi=300, bbox_inches='tight')



# Afficher le graphique
plt.show()






# Obtenir la liste unique des générations
generations = sorted(df['GENERATION'].unique())

# Créer un subplot pour chaque génération
fig, axes = plt.subplots(len(generations), 1, figsize=(15, 8*len(generations)))
fig.suptitle('Distribution des variants par ORF pour chaque génération', fontsize=16)

# Pour chaque génération
for idx, generation in enumerate(generations):
    # Filtrer les données pour cette génération
    gen_data = df[df['GENERATION'] == generation]
    
    # Compter les ORFs pour cette génération
    orf_counts = count_individual_orfs(gen_data['ORF'])
    
    # Créer un DataFrame pour cette génération
    gen_df = pd.DataFrame.from_dict(orf_counts, orient='index', columns=['count'])
    gen_df = gen_df.sort_values('count', ascending=False)
    gen_df['percentage'] = (gen_df['count'] / gen_df['count'].sum()) * 100
    
    # Créer le graphique pour cette génération
    ax = axes[idx] if len(generations) > 1 else axes
    sns.barplot(data=gen_df.reset_index(), x='index', y='count', ax=ax)
    ax.set_xticklabels(ax.get_xticklabels(), rotation=45, ha='right')
    ax.set_xlabel('ORF')
    ax.set_ylabel('Nombre de variants')
    ax.set_title(f'Génération {generation}')

plt.tight_layout()

fig.savefig('distribution_variants_orf_par_generation.png', 
            dpi=300, 
            bbox_inches='tight')

plt.show()


