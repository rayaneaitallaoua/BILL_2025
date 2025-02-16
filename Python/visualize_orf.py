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
results_df['percentage'] = (results_df['count'] / results_df['count'].sum()) * 100

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