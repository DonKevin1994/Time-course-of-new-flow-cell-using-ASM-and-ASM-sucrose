# Installing packages 

library(tidyverse)
library(readr)
library(phyloseq)
library(ggplot2)
library(decontam)
library(scales)
library(qiime2R)

# Importing QIIME2 files for Decontam 

metadata<-read_tsv("TC3_metadatav2.txt")

ASVs <- read_qza("final_decontam_table_TC3_EBC1.qza")

greengenes_taxonomy <- read_qza("RCM_taxonomy.qza")

insertion_tree <- read_qza("RCM_rooted-tree.qza")

# Separating the headers for the greengenes taxonomy file 

taxtable<-greengenes_taxonomy$data %>% as_tibble() %>% separate(Taxon, sep=";", c("Kingdom","Phylum","Class","Order","Family","Genus","Species")) 

# Creating a phyloseq object  

physeq<-phyloseq(otu_table(ASVs$data, taxa_are_rows = T), phy_tree(insertion_tree$data), tax_table(as.data.frame(taxtable) %>% select(-Confidence) %>% column_to_rownames("Feature.ID") %>% as.matrix()), sample_data(metadata %>% as.data.frame() %>% column_to_rownames("SampleID")))

# Creating a dataframe of the phyloseq object 

TC3_CONTROL2_df <- as.data.frame(sample_data(physeq))

# Now to look at the library size 

TC3_CONTROL2_df$LibrarySize<-sample_sums(physeq)

# We want to visualise the library size to make sure most of the EBCs have a lower seq count (just do EBC2's first, do core metrics. Do EBC2's after)

TC3_CONTROL2_df <- TC3_CONTROL2_df[order(TC3_CONTROL2_df$LibrarySize),]
TC3_CONTROL2_df$Index <- seq(nrow(TC3_CONTROL2_df))
ggplot(data= TC3_CONTROL2_df, aes(x=Index, y=LibrarySize, color=EBC1vsControl2vsBiological)) +geom_point()

# Now to identify the prevalence of contaminants 
# After investigating the prevalence plot, we identified a threshold of 0.55 to be best for this dataset 

sample_data(physeq)$is.neg <- sample_data(physeq)$EBC1vsControl2vsBiological == "CONTROL2"

TC3_CONTROL2_contamdf.prev <- isContaminant(physeq, method="prevalence", neg="is.neg", threshold=0.55)

ggplot(data = TC3_CONTROL2_contamdf.prev, aes(x=p)) +
  geom_histogram(binwidth = 0.01) +
  labs(x = 'decontam Score', y='Number of species')

# Now to look at the frequencies 

#TRUE 10 FALSE 1758


# We want to create a plot to look at the presence/absence of features in samples and controls (CONTROL2's)
## This includes making p-a objects of the controls (CONTROL2's) and samples and a new dataframe of prevalence for all samples 

physeq.pa <- transform_sample_counts(physeq, function(abund) 1*(abund>0))

physeq.pa.controls <- prune_samples(sample_data(physeq.pa)$CONTROL2vsControl2vsBiological == "CONTROL2", physeq.pa)

physeq.pa.samples <- prune_samples(sample_data(physeq.pa)$CONTROL2vsControl2vsBiological == "Biological", physeq.pa)

TC3_CONTROL2_df.pa <- data.frame(pa.pos=taxa_sums(physeq.pa.samples), pa.neg=taxa_sums(physeq.pa.controls), contaminant=TC3_CONTROL2_contamdf.prev$contaminant)

ggplot(data=TC3_CONTROL2_df.pa, aes(x=pa.neg, y=pa.pos, color=contaminant)) + geom_point() + xlab("Prevalence (Negative Controls)") + ylab("Prevalence (Samples)") 

#write frequency table to file 

write.table(TC3_CONTROL2_contamdf.prev, file = "/mnt/c/Users/Kevin/QIIME_workflow/OMT/TC3/frequency_table_TC3_CONTROL2.csv",
            
            sep=",", quote = FALSE, col.names=TRUE, row.names=TRUE)

# Now we want to remove the contaminant ASVs 

# As there are issues with biom format and the latest version of R, we will remove these manually 
## To do this we will create a .txt file with the column names "FeatureID" and "Frequency"
## Insert the contaminant ASVs under the "FeatureID" header
## Now we save that and move back into QIIME2 to remove these contaminants


#######  ASSIGNING TAXA ###############

# Import qiime taxonomy file (.qza)

library(qiime2R)
taxonomy <- read_qza("RCM_taxonomy.qza")
taxonomy<-parse_taxonomy(taxonomy$data)

# Convert row names to columns in dataframes, so they can be merged

library(data.table)
taxonomy <- tibble::rownames_to_column(taxonomy, "featureID")
TC3_CONTROL2_contamdf.prev <- tibble::rownames_to_column(TC3_CONTROL2_contamdf.prev, "featureID")

# Join tables to find taxonomy of contaminants
contaminants_taxonomy <- dplyr::semi_join(taxonomy, TC3_CONTROL2_contamdf.prev, by = "featureID")

# Now you can view the contaminant taxa and save this as a file to open in Excel if you want.

write.table(contaminants_taxonomy, file = "/mnt/c/Users/Kevin/QIIME_workflow/OMT/TC3/frequency_table_TC3_CONTROL2_Taxa.csv",
            
            sep=",", quote = FALSE, col.names=TRUE, row.names=TRUE)

#Remove True feature IDs using excel
#Copy pasted the table containing all the assigned taxa (for both contaminants and non-contaminants)
#to my contaminants excel file, went to home > conditional formatting > highlight cell rules > 
#duplicates values > ok (which coloured all the contaminant feature ids). After that, I custom sorted
#based on the feature id column and the cell colour
