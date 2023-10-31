# Analyze GFF Program
This program analyzes any Human chromossome by its features (exons, five prime UTR etc). It downloads a gff3 file from Ensembl website for the chromosome in question and computes the number of occurences for all the features in question. It then display for each feature the top 10 instances with the transcript ID the number of occurences for that feature the gene it belongs gene with a small description.

Usage: 
./analyze_GFF_features.sh <chromosome number>

