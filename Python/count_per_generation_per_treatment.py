import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

#Lecture du fichier csv
df = pd.read_csv('sv_with_orf.csv')

# Exclure P15 car pas de traitements thermiques
df = df[df['GENERATION'] != 'P15']

# Créer une colonne pour le type de choc thermique
df['SHOCK_TYPE'] = df['ECHANTILLON'].apply(lambda x: 'cold' if x <= 5 else 'hot')
    

orf_counts = {}
        

def process_generation(gen_df):
    #On itère sur les lignes de gen_df
    for _, row in gen_df.iterrows():
        #On stock le choc thermique et le type de mutation
        shock = row['SHOCK_TYPE']
        mutation = row['TYPE DE MUTATION'].lower()
        
        #On sépare les ORFs multiples
        if pd.notna(row['ORF']):
            orfs = row['ORF'].split('|')
            for orf in orfs:
                #Si un orf n'est pas dans le dictionnaire alors on crée la clef ainsi que les differentes valeurs
                if orf not in orf_counts:
                    orf_counts[orf] = {
                        'cold_del': 0, 'cold_ins': 0,
                        'hot_del': 0, 'hot_ins': 0
                    }
                #On ajoute +1 a la bonne valeur
                orf_counts[orf][f'{shock}_{mutation}'] += 1

    # On convertit en DataFrame
    counts_df = pd.DataFrame.from_dict(orf_counts, orient='index')
    #On ajoute une colonne total qui permettra d'extraire les orfs ayant le plus de variants
    counts_df['total'] = counts_df.sum(axis=1)
    #on retourne les 15 orfs ayant le plus de variants
    return counts_df.sort_values('total', ascending=False).head(15)

#On récupère les générations
generations = sorted(df['GENERATION'].unique())
#on crée les graphes par générations
fig, axes = plt.subplots(len(generations), 1, figsize=(15, 8*len(generations)))
#Titre principal
fig.suptitle('Distribution des variants par condition et type de mutation', fontsize=16, y=0.95)

#On définit les couleurs
colors = {
    'cold_del': '#2B6CB0',  # Bleu foncé
    'cold_ins': '#4299E1',  # Bleu clair
    'hot_del': '#C53030',   # Rouge foncé
    'hot_ins': '#F56565'    # Rouge clair
}



for idx, generation in enumerate(generations):
    #On recrupère les lignes génération en cours
    gen_df = df[df['GENERATION'] == generation]
    #On appelle la fonction précèdement créée
    counts_df = process_generation(gen_df)
    
    #On obtient l'axe correct
    ax = axes[idx]
    
    # Créer le graphique empilé
    #bottom_cold = pd.Series(0, index=counts_df.index)
    #bottom_hot = pd.Series(0, index=counts_df.index)
    
    # Tracer les barres
    width = 0.35
    x = range(len(counts_df))
    #On trace les barres pour le choc froid
    #Une barre pour les délétions
    ax.bar(x, counts_df['cold_del'], width, 
            label='Délétions - froid', color=colors['cold_del'])
    #Une barre pour les insertions
    ax.bar(x, counts_df['cold_ins'], width,
            bottom=counts_df['cold_del'],      #Permet d'empiler les barres insertion et deletion
            label='Insertions - froid', color=colors['cold_ins'])
    
    #On trace pour le choc chaud
    #Une barre pour les délétions
    ax.bar([i + width for i in x], counts_df['hot_del'], width,
            label='Délétions - chaud', color=colors['hot_del'])
    #Une barre pour les insertions
    ax.bar([i + width for i in x], counts_df['hot_ins'], width,
            bottom=counts_df['hot_del'],
            label='Insertions - chaud', color=colors['hot_ins'])
    
    # Configurer l'axe
    ax.set_title(f'Génération {generation}')
    ax.set_ylabel('Nombre de variants')
    ax.set_xticks([i + width/2 for i in x])
    ax.set_xticklabels([orf.replace('CyHV3_', '') for orf in counts_df.index],
                        rotation=45, ha='right')
    
    ax.legend()
    
    #On ajuste la grille
    ax.grid(True, axis='y', linestyle='--', alpha=0.7)

#On ajuste la mise en page
plt.tight_layout()

fig.savefig('variants_per_treatment_per_gen.png', dpi=300, bbox_inches='tight')
    
# Afficher le graphique
plt.show()