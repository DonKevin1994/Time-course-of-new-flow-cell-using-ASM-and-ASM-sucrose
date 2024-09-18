#!/bin/bash

#11/10/2022

conda activate qiime2-2022.8
cd /mnt/c/Users/Kevin/QIIME_workflow/OMT/Run2/OMT_data/run_1

#Casava 1.8 paired-end demultiplexed fastq (according to the importing data tutorial on QIIME)
#Unzip main zip file 

unzip -q OMT_data.zip

#Importing data (get rid of the unzipped files and just have the zipped files in the folder which is the fastq.gz format)

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path /mnt/c/Users/Kevin/QIIME_workflow/OMT/TC/OMT_data/run_1_2 \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path OMT_TC_demux-paired-end.qza


qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path /mnt/c/Users/Kevin/QIIME_workflow/OMT/Run1/run_1 \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path OMT_run_1_demux-paired-end.qza

qiime vsearch merge-pairs \
  --i-demultiplexed-seqs MS_and_Some_TC_demux-paired-end.qza \
  --o-merged-sequences MS_and_Some_TC_demux_joined.qza \
  --o-unmerged-sequences MS_and_Some_TC_demux_unjoined.qza
 


#Visulaise demux results 


qiime demux summarize \
  --i-data MS_and_Some_TC_demux_joined.qza \
  --o-visualization MS_and_Some_TC_demux_joined.qzv


#Using deblur to clean the data according to sequencing error


qiime quality-filter q-score \
 --i-demux MS_and_Some_TC_demux_joined.qza \
 --o-filtered-sequences MS_and_Some_TC_demux_filtered.qza \
 --o-filter-stats MS_and_Some_TC_demux_filtered_stats.qza


 
 #^This no longer works


 
 
#Need to clean and trim data for deblur to be sure that sequence quality is high (here they trim at 220 bp of 251 bp reads)
#Check trim length with Laura


qiime deblur denoise-16S \
  --i-demultiplexed-seqs MS_and_Some_TC_demux_filtered.qza \
  --p-trim-length 220 \
  --o-representative-sequences MS_and_Some_TC_rep_seqs.qza \
  --o-table MS_and_Some_TC_table1.qza \
  --p-sample-stats \
  --o-stats MS_and_Some_TC_stats.qza




qiime deblur visualize-stats \
  --i-deblur-stats MS_and_Some_TC_stats.qza \
  --o-visualization MS_and_Some_TC_deblur_stats.qzv


############################################


#Obtain information on how many sequences are associated with each sample


qiime feature-table summarize \
  --i-table MS_and_Some_TC_table1.qza \
  --o-visualization MS_and_Some_TC_table1.qzv \
  --m-sample-metadata-file MS_and_Some_TC_Mapping.txt


 qiime feature-table tabulate-seqs \
  --i-data MS_and_Some_TC_rep_seqs.qza \
  --o-visualization MS_and_Some_TC_rep_seqs.qzv




#Merge feature tables from run 1 and 2 and merge rep_seqs from run 1 and 2 and MS_and_Some_TC_rep_seqs.qza
#Did this to inlcude TC2 PBS and ASM control samples that were done on a separate run


qiime feature-table merge \
    --i-tables OMT_data_run_1_table.qza OMT_data_run_2_table.qza MS_and_Some_TC_table.qza \
    --o-merged-table OMT_data_merged_table.qza


qiime feature-table merge-seqs \
  --i-data OMT_data_run_1_rep_seqs.qza OMT_data_run_2_rep_seqs.qza MS_and_Some_TC_rep_seqs.qza \
  --o-merged-data OMT_data_merged_rep-seqs.qza


#Generate a tree for phylogenetic diversity analyses


qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences OMT_data_merged_rep-seqs.qza \
  --o-alignment aligned_OMT_merged_rep_seqs.qza \
  --o-masked-alignment masked-aligned_OMT_data_merged_rep_seqs.qza \
  --o-tree OMT_data_merged_unrooted-tree.qza \
  --o-rooted-tree OMT_data_merged_rooted-tree.qza


#Filtering metadata column 'NAME' by TC (Time-course Experiment)


qiime feature-table filter-samples \
--i-table OMT_data_merged_table.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "EBC1vsControl2vsBiological='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_table.qza


qiime feature-table summarize \
--i-table TC2_table.qza \
--o-visualization TC2_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


#Taxonomical analysis


qiime feature-classifier classify-sklearn \
  --i-classifier gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads OMT_data_merged_rep-seqs.qza \
  --o-classification OMT_data_merged_taxonomy.qza


qiime metadata tabulate \
  --m-input-file OMT_data_merged_taxonomy.qza \
  --o-visualization OMT_data_merged_taxonomy.qzv


#Decontam was run for EBC1


qiime feature-table filter-features \
--i-table TC2_table.qza \
--p-exclude-ids \
--m-metadata-file ContaminantsToRemove_TC2_EBC1.txt \
--o-filtered-table decontam_table_TC2_EBC1.qza


qiime feature-table summarize \
--i-table decontam_table_TC2_EBC1.qza \
--o-visualization decontam_table_TC2_EBC1.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


############## REMOVING SINGELTONS AND SAMPLES WITH LOW READS ############


# Removing singletons that have been created from removing contaminants before samples with low reads


qiime feature-table filter-features \
--i-table decontam_table_TC2_EBC1.qza  \
--p-min-frequency 2 \
--o-filtered-table final_decontam_table_TC2_EBC1.qza


qiime feature-table summarize \
--i-table final_decontam_table_TC2_EBC1.qza  \
--o-visualization final_decontam_table_TC2_EBC1.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


#Decontam was run for Control2 


qiime feature-table filter-features \
--i-table final_decontam_table_TC2_EBC1.qza \
--p-exclude-ids \
--m-metadata-file ContaminantsToRemove_TC2_Control2.txt \
--o-filtered-table decontam_table_TC2_Control2.qza
 
qiime feature-table summarize \
--i-table decontam_table_TC2_Control2.qza \
--o-visualization decontam_table_TC2_Control2.qzv \
--m-sample-metadata-file TC2_metadatav2.txt
 
##############
REMOVING SINGELTONS AND SAMPLES WITH LOW READS ############
 
# Removing
singletons that have been created from removing contaminants before samples
with low reads
 
qiime feature-table filter-features \
--i-table decontam_table_TC2_Control2.qza  \
--p-min-frequency 2 \
--o-filtered-table final_decontam_table_TC2_Control2.qza
 
qiime feature-table summarize \
--i-table final_decontam_table_TC2_Control2.qza  \
--o-visualization final_decontam_table_TC2_Control2.qzv \
--m-sample-metadata-file TC2_metadatav2.txt
















#Filtering samples by D0vsD3, D3vsD7 and D7vsD10
#Run core metrics, alpha and beta diversities 
#Prep file for Maaslin analysis 
#Filter biological samples of TC2 first 




#D0vsD3


qiime feature-table filter-samples \
--i-table TC2_table.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "D0vsD3='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_D0vsD3_table.qza


qiime feature-table summarize \
--i-table TC2_D0vsD3_table.qza \
--o-visualization TC2_D0vsD3_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --i-table TC2_D0vsD3_table.qza \
  --p-sampling-depth 37671 \
  --m-metadata-file TC2_metadatav2.txt  \
  --output-dir TC2_D0vsD3_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC2_D0vsD3_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column D0vsD3\
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D0vsD3_CoreDiversity_Results/unweighted_unifrac_significance_TC2_D0vsD3.qzv


qiime diversity alpha-rarefaction \
  --i-table TC2_D0vsD3_table.qza \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --p-max-depth 37671 \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D0vsD3_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC2_D0vsD3_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D0vsD3_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC2_D0vsD3_table.qza \
  --i-taxonomy OMT_Data_merged_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC2_D0vsD3-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC2_D0vsD3-table-L7.qza \
--o-relative-frequency-table TC2_D0vsD3-frequency-table-L7.qza \
--output-dir TC2_D0vsD3-frequency-L7/


qiime tools export \
--input-path TC2_D0vsD3-frequency-table-L7.qza \
--output-path TC2_D0vsD3-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC2_D0vsD3-frequency-L7/feature-table.biom \
-o TC2_D0vsD3-frequency-L7/TC2_D0vsD3-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv


#D3vsD7


qiime feature-table filter-samples \
--i-table TC2_table.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "D3vsD7='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_D3vsD7_table.qza


qiime feature-table summarize \
--i-table TC2_D3vsD7_table.qza \
--o-visualization TC2_D3vsD7_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --i-table TC2_D3vsD7_table.qza \
  --p-sampling-depth 53189 \
  --m-metadata-file TC2_metadatav2.txt  \
  --output-dir TC2_D3vsD7_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC2_D3vsD7_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column D3vsD7\
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D3vsD7_CoreDiversity_Results/unweighted_unifrac_significance_TC2_D3vsD7.qzv


qiime diversity alpha-rarefaction \
  --i-table TC2_D3vsD7_table.qza \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --p-max-depth 53189 \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D3vsD7_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC2_D3vsD7_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D3vsD7_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC2_D3vsD7_table.qza \
  --i-taxonomy OMT_Data_merged_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC2_D3vsD7-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC2_D3vsD7-table-L7.qza \
--o-relative-frequency-table TC2_D3vsD7-frequency-table-L7.qza \
--output-dir TC2_D3vsD7-frequency-L7/


qiime tools export \
--input-path TC2_D3vsD7-frequency-table-L7.qza \
--output-path TC2_D3vsD7-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC2_D3vsD7-frequency-L7/feature-table.biom \
-o TC2_D3vsD7-frequency-L7/TC2_D3vsD7-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv


#D7vsD10


qiime feature-table filter-samples \
--i-table TC2_table.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "D7vsD10='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_D7vsD10_table.qza


qiime feature-table summarize \
--i-table TC2_D7vsD10_table.qza \
--o-visualization TC2_D7vsD10_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --i-table TC2_D7vsD10_table.qza \
  --p-sampling-depth 48380 \
  --m-metadata-file TC2_metadatav2.txt  \
  --output-dir TC2_D7vsD10_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC2_D7vsD10_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column D7vsD10\
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D7vsD10_CoreDiversity_Results/unweighted_unifrac_significance_TC2_D7vsD10.qzv


qiime diversity alpha-rarefaction \
  --i-table TC2_D7vsD10_table.qza \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --p-max-depth 48380 \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D7vsD10_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC2_D7vsD10_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D7vsD10_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC2_D7vsD10_table.qza \
  --i-taxonomy OMT_Data_merged_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC2_D7vsD10-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC2_D7vsD10-table-L7.qza \
--o-relative-frequency-table TC2_D7vsD10-frequency-table-L7.qza \
--output-dir TC2_D7vsD10-frequency-L7/


qiime tools export \
--input-path TC2_D7vsD10-frequency-table-L7.qza \
--output-path TC2_D7vsD10-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC2_D7vsD10-frequency-L7/feature-table.biom \
-o TC2_D7vsD10-frequency-L7/TC2_D7vsD10-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv


#Taxonomy bar plots


#D0vsD3


qiime taxa barplot \
  --i-table TC2_D0vsD3_table.qza \
  --i-taxonomy OMT_data_merged_taxonomy.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D0vsD3_taxbarplot.qzv


#D3vsD7


qiime taxa barplot \
  --i-table TC2_D3vsD7_table.qza \
  --i-taxonomy OMT_data_merged_taxonomy.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D3vsD7_taxbarplot.qzv


#D7vsD10


qiime taxa barplot \
  --i-table TC2_D7vsD10_table.qza \
  --i-taxonomy OMT_data_merged_taxonomy.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D7vsD10_taxbarplot.qzv


#Filter samples by donor numbers 


#8


qiime feature-table filter-samples \
--i-table TC2_table.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "DonorNumber='D8'" \
--o-filtered-table TC2_Donor8_table.qza
 
qiime feature-table summarize \
--i-table TC2_Donor8_table.qza \
--o-visualization TC2_Donor8_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


qiime taxa barplot \
  --i-table TC2_Donor8_table.qza \
  --i-taxonomy OMT_data_merged_taxonomy.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_Donor8_taxbarplot.qzv


#Control vs Biological 


qiime feature-table filter-samples \
--i-table final_decontam_table_TC2_Control2.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "EBC1vsControl2vsBiological='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_table.qza


qiime feature-table summarize \
--i-table TC2_table.qza \
--o-visualization TC2_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt






qiime feature-table filter-samples \
--i-table TC2_table.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "ControlvsBiological='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_ControlvsBiological_table.qza


qiime feature-table summarize \
--i-table TC2_ControlvsBiological_table.qza \
--o-visualization TC2_ControlvsBiological_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --i-table TC2_ControlvsBiological_table.qza \
  --p-sampling-depth 2 \
  --m-metadata-file TC2_metadatav2.txt  \
  --output-dir TC2_ControlvsBiological_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC2_ControlvsBiological_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column ControlvsBiological\
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_ControlvsBiological_CoreDiversity_Results/unweighted_unifrac_significance_TC2_ControlvsBiological.qzv


qiime diversity alpha-rarefaction \
  --i-table TC2_ControlvsBiological_table.qza \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --p-max-depth 2 \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_ControlvsBiological_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC2_ControlvsBiological_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_ControlvsBiological_CoreDiversity_Results/observed_features_significance.qzv


#Filter samples to only contain EBC1, Control2 and Biological 


qiime feature-table filter-samples \
--i-table TC2_table.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "EBC1vsControl2vsBiological='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_table.qza


qiime feature-table summarize \
--i-table TC2_ControlvsBiological_table.qza \
--o-visualization TC2_ControlvsBiological_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


#Alternative contaminant removal


#EBC1


qiime feature-table filter-samples \
--i-table OMT_data_merged_table.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "EBC1='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_EBC1_table.qza


qiime feature-table summarize \
--i-table TC2_EBC1_table.qza \
--o-visualization TC2_EBC1_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt
qiime taxa barplot \
  --i-table TC2_EBC1_table.qza \
  --i-taxonomy OMT_data_merged_taxonomy.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_EBC1_taxbarplot.qzv


#Control2


qiime feature-table filter-samples \
--i-table OMT_data_merged_table.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "Control2='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_Control2_table.qza


qiime feature-table summarize \
--i-table TC2_Control2_table.qza \
--o-visualization TC2_Control2_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


qiime taxa barplot \
  --i-table TC2_Control2_table.qza \
  --i-taxonomy OMT_data_merged_taxonomy.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_Control2_taxbarplot.qzv


#remove contaminants RECCS


qiime feature-table filter-features \
--i-table TC2_table.qza \
--p-exclude-ids \
--m-metadata-file ContaminantsToRemove_TC2_RECCS.txt \
--o-filtered-table TC2_RECCS.qza
 
qiime feature-table summarize \
--i-table TC2_RECCS.qza \
--o-visualization TC2_RECCS.qzv \
--m-sample-metadata-file TC2_metadatav2.txt
 
##############
REMOVING SINGELTONS AND SAMPLES WITH LOW READS ############
 
# Removing
singletons that have been created from removing contaminants before samples
with low reads
 
qiime feature-table filter-features \
--i-table TC2_RECCS.qza  \
--p-min-frequency 2 \
--o-filtered-table final_TC2_RECCS.qza
 
qiime feature-table summarize \
--i-table final_TC2_RECCS.qza  \
--o-visualization final_TC2_RECCS.qzv \
--m-sample-metadata-file TC2_metadatav2.txt




#ControlvsBiological


qiime feature-table filter-samples \
--i-table final_TC2_RECCS.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "EBC1vsControl2vsBiological='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_table.qza


qiime feature-table summarize \
--i-table TC2_table.qza \
--o-visualization TC2_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt






qiime feature-table filter-samples \
--i-table TC2_table.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "ControlvsBiological='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_ControlvsBiological_table.qza


qiime feature-table summarize \
--i-table TC2_ControlvsBiological_table.qza \
--o-visualization TC2_ControlvsBiological_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --i-table TC2_ControlvsBiological_table.qza \
  --p-sampling-depth 2 \
  --m-metadata-file TC2_metadatav2.txt  \
  --output-dir TC2_ControlvsBiological_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC2_ControlvsBiological_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column ControlvsBiological\
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_ControlvsBiological_CoreDiversity_Results/unweighted_unifrac_significance_TC2_ControlvsBiological.qzv


qiime diversity beta-group-significance \
  --i-distance-matrix TC2_ControlvsBiological_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column EBC1vsControl2vsBiological\
  --m-metadata-file TC2_metadatav2.txt \
  --p-pairwise \
  --o-visualization TC2_ControlvsBiological_CoreDiversity_Results/unweighted_unifrac_significance_TC2_EBC1vsControl2vsBiological.qzv










qiime diversity alpha-rarefaction \
  --i-table TC2_ControlvsBiological_table.qza \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --p-max-depth 2 \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_ControlvsBiological_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC2_ControlvsBiological_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_ControlvsBiological_CoreDiversity_Results/observed_features_significance.qzv




#Filter out D0vsD3, D3vsD7 and D7vsD10 
#run core metrics, alpha, beta diversity and 
#Maaslin file prep 


#D0vsD3


qiime feature-table filter-samples \
--i-table final_TC2_RECCS.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "D0vsD3='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_D0vsD3_table.qza


qiime feature-table summarize \
--i-table TC2_D0vsD3_table.qza \
--o-visualization TC2_D0vsD3_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --i-table TC2_D0vsD3_table.qza \
  --p-sampling-depth 1090 \
  --m-metadata-file TC2_metadatav2.txt  \
  --output-dir TC2_D0vsD3_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC2_D0vsD3_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column D0vsD3\
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D0vsD3_CoreDiversity_Results/unweighted_unifrac_significance_TC2_D0vsD3.qzv


qiime diversity alpha-rarefaction \
  --i-table TC2_D0vsD3_table.qza \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --p-max-depth 1090 \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D0vsD3_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC2_D0vsD3_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D0vsD3_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC2_D0vsD3_table.qza \
  --i-taxonomy OMT_Data_merged_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC2_D0vsD3-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC2_D0vsD3-table-L7.qza \
--o-relative-frequency-table TC2_D0vsD3-frequency-table-L7.qza \
--output-dir TC2_D0vsD3-frequency-L7/


qiime tools export \
--input-path TC2_D0vsD3-frequency-table-L7.qza \
--output-path TC2_D0vsD3-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC2_D0vsD3-frequency-L7/feature-table.biom \
-o TC2_D0vsD3-frequency-L7/TC2_D0vsD3-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv


#D3vsD7


qiime feature-table filter-samples \
--i-table final_TC2_RECCS.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "D3vsD7='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_D3vsD7_table.qza


qiime feature-table summarize \
--i-table TC2_D3vsD7_table.qza \
--o-visualization TC2_D3vsD7_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --i-table TC2_D3vsD7_table.qza \
  --p-sampling-depth 1090 \
  --m-metadata-file TC2_metadatav2.txt  \
  --output-dir TC2_D3vsD7_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC2_D3vsD7_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column D3vsD7\
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D3vsD7_CoreDiversity_Results/unweighted_unifrac_significance_TC2_D3vsD7.qzv


qiime diversity alpha-rarefaction \
  --i-table TC2_D3vsD7_table.qza \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --p-max-depth 1090 \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D3vsD7_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC2_D3vsD7_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D3vsD7_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC2_D3vsD7_table.qza \
  --i-taxonomy OMT_Data_merged_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC2_D3vsD7-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC2_D3vsD7-table-L7.qza \
--o-relative-frequency-table TC2_D3vsD7-frequency-table-L7.qza \
--output-dir TC2_D3vsD7-frequency-L7/


qiime tools export \
--input-path TC2_D3vsD7-frequency-table-L7.qza \
--output-path TC2_D3vsD7-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC2_D3vsD7-frequency-L7/feature-table.biom \
-o TC2_D3vsD7-frequency-L7/TC2_D3vsD7-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv


#D7vsD10


qiime feature-table filter-samples \
--i-table final_TC2_RECCS.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "D7vsD10='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_D7vsD10_table.qza


qiime feature-table summarize \
--i-table TC2_D7vsD10_table.qza \
--o-visualization TC2_D7vsD10_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --i-table TC2_D7vsD10_table.qza \
  --p-sampling-depth 3483 \
  --m-metadata-file TC2_metadatav2.txt  \
  --output-dir TC2_D7vsD10_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC2_D7vsD10_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column D7vsD10\
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D7vsD10_CoreDiversity_Results/unweighted_unifrac_significance_TC2_D7vsD10.qzv


qiime diversity alpha-rarefaction \
  --i-table TC2_D7vsD10_table.qza \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --p-max-depth 3483 \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D7vsD10_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC2_D7vsD10_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D7vsD10_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC2_D7vsD10_table.qza \
  --i-taxonomy OMT_Data_merged_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC2_D7vsD10-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC2_D7vsD10-table-L7.qza \
--o-relative-frequency-table TC2_D7vsD10-frequency-table-L7.qza \
--output-dir TC2_D7vsD10-frequency-L7/


qiime tools export \
--input-path TC2_D7vsD10-frequency-table-L7.qza \
--output-path TC2_D7vsD10-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC2_D7vsD10-frequency-L7/feature-table.biom \
-o TC2_D7vsD10-frequency-L7/TC2_D7vsD10-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv


#Taxonomy bar plots


#D0vsD3


qiime taxa barplot \
  --i-table TC2_D0vsD3_table.qza \
  --i-taxonomy OMT_data_merged_taxonomy.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D0vsD3_taxbarplot.qzv


#D3vsD7


qiime taxa barplot \
  --i-table TC2_D3vsD7_table.qza \
  --i-taxonomy OMT_data_merged_taxonomy.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D3vsD7_taxbarplot.qzv


#D7vsD10


qiime taxa barplot \
  --i-table TC2_D7vsD10_table.qza \
  --i-taxonomy OMT_data_merged_taxonomy.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_D7vsD10_taxbarplot.qzv


#Day 


qiime feature-table filter-samples \
--i-table final_TC2_RECCS.qza \
--m-metadata-file TC2_metadatav2.txt \
--p-where "Day='NA'" \
--p-exclude-ids \
--o-filtered-table TC2_Day_table.qza


qiime feature-table summarize \
--i-table TC2_Day_table.qza \
--o-visualization TC2_Day_table.qzv \
--m-sample-metadata-file TC2_metadatav2.txt


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --i-table TC2_Day_table.qza \
  --p-sampling-depth 1090 \
  --m-metadata-file TC2_metadatav2.txt  \
  --output-dir TC2_Day_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC2_Day_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column Day\
  --m-metadata-file TC2_metadatav2.txt \
  --p-pairwise \
  --o-visualization TC2_Day_CoreDiversity_Results/unweighted_unifrac_significance_TC2_Day.qzv


qiime diversity alpha-rarefaction \
  --i-table TC2_Day_table.qza \
  --i-phylogeny OMT_data_merged_rooted-tree.qza \
  --p-max-depth 1090 \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_Day_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC2_Day_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_Day_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa barplot \
  --i-table TC2_Day_table.qza \
  --i-taxonomy OMT_data_merged_taxonomy.qza \
  --m-metadata-file TC2_metadatav2.txt \
  --o-visualization TC2_Day_taxbarplot.qzv






















































