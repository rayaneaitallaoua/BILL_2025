# Step 1: Load necessary libraries ----
library(tidyverse)
library(gridExtra)

# Step 2: Import the data ----
# chemin d'import à synchroniser avec Théo
# pense à récupérer le nombre de reads par valeur de AF et GQ, à représenter sur
# chaque colonne

#penser à la normalisation des valuer AF et GQ?

af_data <- read.table(".\\fichiers_utilises\\AF_per_SV.txt", header = FALSE,
                      col.names = c("Frequency", "AF"))
gq_data <- read.table(".\\fichiers_utilises\\GQ_per_SNP.txt", header = FALSE,
                      col.names = c("Frequency", "GQ"))

# Step 3: Check the structure of the data ----
glimpse(af_data)
glimpse(gq_data)

# Step 4: Create the histograms ----
## à créer 2 hist SNP et VS par génération, comparer les générations entre eux

af_plot <- ggplot(af_data, aes(x = AF)) +
  geom_histogram(binwidth = 0.05, fill = "blue", color = "black", alpha = 0.7) +  # Increased binwidth
  labs(title = "Allele Frequency Distribution per SV", x = "Allele Frequency (AF)", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

gq_plot <- ggplot(gq_data, aes(x = GQ)) +
  geom_histogram(binwidth = 1, fill = "green", color = "black", alpha = 0.7) +
  labs(title = "Genotype Quality Distribution per SNP", x = "Genotype Quality (GQ)", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

# Step 5: Arrange the plots side by side ----
grid.arrange(af_plot, gq_plot, ncol = 2)

## à rajouter un moyen de sortir tout les histograme de façon organisé
# dans un dossier
