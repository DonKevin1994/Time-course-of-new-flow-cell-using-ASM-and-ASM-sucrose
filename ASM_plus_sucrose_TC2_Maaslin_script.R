############          TC2             ##################

#TC2_D0vsD3

library(Maaslin2)

metadata<-read.table("TC2_metadatav2.txt", header = TRUE, sep = "\t",
                     row.names = 1, stringsAsFactors = FALSE, check.names = FALSE)

data<-read.csv(file = "TC2_D0vsD3-frequency-table-L7F.csv", header = TRUE, sep = ",",
               row.names = 1, stringsAsFactors = FALSE, check.names = FALSE)


fit_data<-Maaslin2(
  input_data = data,
  input_metadata = metadata,
  output = "Maaslin2_Results_TC2_D0vsD3NONE",
  fixed_effects = c("D0vsD3"),
  reference = c(("D0,D3")),
  normalization = "CLR",
  max_significance = 0.05,
  transform = "NONE")

#TC2_D3vsD7

library(Maaslin2)

metadata<-read.table("TC2_metadatav2.txt", header = TRUE, sep = "\t",
                     row.names = 1, stringsAsFactors = FALSE, check.names = FALSE)

data<-read.csv(file = "TC2_D3vsD7-frequency-table-L7F.csv", header = TRUE, sep = ",",
               row.names = 1, stringsAsFactors = FALSE, check.names = FALSE)


fit_data<-Maaslin2(
  input_data = data,
  input_metadata = metadata,
  output = "Maaslin2_Results_TC2_D3vsD7NONE",
  fixed_effects = c("D3vsD7"),
  reference = c(("D3,D7")),
  normalization = "CLR",
  max_significance = 0.05,
  transform = "NONE")

#TC2_D7vsD10

library(Maaslin2)

metadata<-read.table("TC2_metadatav2.txt", header = TRUE, sep = "\t",
                     row.names = 1, stringsAsFactors = FALSE, check.names = FALSE)

data<-read.csv(file = "TC2_D7vsD10-frequency-table-L7F.csv", header = TRUE, sep = ",",
               row.names = 1, stringsAsFactors = FALSE, check.names = FALSE)


fit_data<-Maaslin2(
  input_data = data,
  input_metadata = metadata,
  output = "Maaslin2_Results_TC2_D7vsD10NONE",
  fixed_effects = c("D7vsD10"),
  reference = c(("D7,D10")),
  normalization = "CLR",
  max_significance = 0.05,
  transform = "NONE")

#Day 

library(Maaslin2)

metadata<-read.table("TC2_metadatav2.txt", header = TRUE, sep = "\t",
                     row.names = 1, stringsAsFactors = FALSE, check.names = FALSE)

data<-read.csv(file = "TC2_Day-frequency-table-L7F.csv", header = TRUE, sep = ",",
               row.names = 1, stringsAsFactors = FALSE, check.names = FALSE)


fit_data<-Maaslin2(
  input_data = data,
  input_metadata = metadata,
  output = "Maaslin2_Results_TC2_Testing",
  fixed_effects = c("Day"),
  reference = c("D0,D3,D7,D10"),
  normalization = "CLR",
  max_significance = 0.05,
  transform = "NONE")

########## ABundance heatmap ############

library(tidyverse)
library(qiime2R)

metadata<-read.table("TC2_metadatav2.txt", header = TRUE, sep = "\t")

SVs<-read_qza("TC2_D0vsD3_table.qza")$data
taxonomy<-read_qza("OMT_data_merged_taxonomy.qza")$data

SVs<-apply(SVs, 2, function(x) x/sum(x)*100) #convert to percent

SVsToPlot<-  
  data.frame(MeanAbundance=rowMeans(SVs)) %>% #find the average abundance of a SV
  rownames_to_column("Feature.ID") %>%
  arrange(desc(MeanAbundance)) %>%
  top_n(30, MeanAbundance) %>%
  pull(Feature.ID) #extract only the names from the table

SVs %>%
  as.data.frame() %>%
  rownames_to_column("Feature.ID") %>%
  gather(-Feature.ID, key="SampleID", value="Abundance") %>%
  mutate(Feature.ID=if_else(Feature.ID %in% SVsToPlot,  Feature.ID, "Remainder")) %>% #flag features to be collapsed
  group_by(SampleID, Feature.ID) %>%
  summarize(Abundance=sum(Abundance)) %>%
  left_join(metadata) %>%
  mutate(NormAbundance=(Abundance+0.01)) %>% # do a log10 transformation after adding a 0.01% pseudocount. Could also add 1 read before transformation to percent
  left_join(taxonomy) %>%
  mutate(Feature=paste(Feature.ID, Taxon)) %>%
  mutate(Feature=gsub("[kpcofgs]__", "", Feature)) %>% # trim out leading text from taxonomy string
  ggplot(aes(x=SampleID, y=Feature, fill=NormAbundance)) +
  geom_tile() +
  theme_q2r() +
  theme(axis.text.x=element_text(size = 10, angle=45, hjust=1)) +
  theme(axis.text.y=element_text(size = 10, hjust=1)) +
  scale_fill_viridis_c(name="(% Abundance)")
ggsave("heatmap1.pdf", height=4, width=11, device="pdf") # save a PDF 6 inches by 6 inches


