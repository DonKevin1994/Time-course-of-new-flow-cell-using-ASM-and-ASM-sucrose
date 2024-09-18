#!/bin/bash

#Importing data (get rid of the unzipped files and just have the zipped files in the folder which is the fastq.gz format)

cd /mnt/c/Users/Kevin/QIIME_workflow/OMT/RCM
conda activate qiime2-2023.7
conda activate qiime2-amplicon-2024.2

#Upload files from local to remote directory

sftp a1788947@a1788947vm.services.adelaide.edu.au
cd /home/a1788947/RCM

#logout of remote directory and login in to vm 

ssh a1788947@a1788947vm.services.adelaide.edu.au

#start running qiime commands with 

apptainer exec /home/singularity_package/core_latest.sif qiime (command here)

#Run qiime 

  qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path /mnt/c/Users/Kevin/QIIME_workflow/OMT/RCM \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path RCM_demux-paired-end.qza

#Joining reads

qiime vsearch merge-pairs \
  --i-demultiplexed-seqs RCM_demux-paired-end.qza \
  --o-merged-sequences RCM_demux_joined.qza

 qiime vsearch merge-pairs \
  --i-demultiplexed-seqs RCM_demux-paired-end.qza \
  --o-merged-sequences RCM_demux_joined.qza

#Visulaise demux results 

 qiime demux summarize \
  --i-data RCM_demux_joined.qza \
  --o-visualization RCM_demux_joined.qzv

#Need to clean and trim data for deblur to be sure that sequence quality is high 

 qiime deblur denoise-16S \
  --i-demultiplexed-seqs  RCM_demux_joined.qza \
  --p-trim-length 252 \
  --o-representative-sequences RCM_rep_seqs.qza \
  --o-table RCM_table.qza \
  --p-sample-stats \
  --o-stats RCM_stats.qza


 qiime deblur visualize-stats \
  --i-deblur-stats RCM_stats.qza \
  --o-visualization RCM_deblur_stats.qzv

#Obtain information on how many sequences are associated with each sample

 qiime feature-table summarize \
  --i-table RCM_table.qza \
  --o-visualization RCM_table.qzv \
  --m-sample-metadata-file RCM_and_TC3_metadatav3.txt

 qiime feature-table tabulate-seqs \
  --i-data RCM_rep_seqs.qza \
  --o-visualization RCM_rep_seqs.qzv

#Generate a tree for phylogenetic diversity analyses 

 qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences RCM_rep_seqs.qza \
  --o-alignment aligned_RCM_rep_seqs.qza \
  --o-masked-alignment masked-aligned_RCM_rep_seqs.qza \
  --o-tree RCM_unrooted-tree.qza \
  --o-rooted-tree RCM_rooted-tree.qza

 qiime feature-classifier classify-sklearn \
  --i-classifier gg_2022_10_backbone.v4.nb.qza \
  --i-reads RCM_rep_seqs.qza \
  --o-classification RCM_taxonomy.qza

cd /Users/dhk5177/Desktop/TC3




############### TIME-COURSE EXPERIMENT (TC3) ##########################


#Filtering metadata column 'NAME' by TC (Time-course Experiment)


qiime feature-table filter-samples \
--i-table RCM_table.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "Experiment='TC3'" \
--o-filtered-table TC3_table.qza


qiime feature-table summarize \
--i-table TC3_table.qza \
--o-visualization TC3_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


^this has EBC1, Control2, Biological samples  in it


#Filtering EBC1’s, EBC2’s and Control2 samples separately to 
#To look at potential contaminants prior to running 
#Through Decontam 


#EBC1


qiime feature-table filter-samples \
--i-table TC3_table.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "EBC1='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_EBC1_table.qza


qiime feature-table summarize \
--i-table TC3_EBC1_table.qza \
--o-visualization TC3_EBC1_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


qiime taxa barplot \
  --i-table TC3_EBC1_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_EBC1_taxbarplot.qzv


#EBC2 (TC3 column has NA’s for EBC2’s)
#But you ran it prior to adding the NA’s 
#So you have TC3_EBC2_table.qza, its qzv and the tax 
#barplot for EBC2’s




#qiime feature-table filter-samples \
--i-table TC3_table.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "EBC2='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_EBC2_table.qza
 
#qiime feature-table summarize \
--i-table TC3_EBC2_table.qza \
--o-visualization TC3_EBC2_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt
 
#qiime taxa barplot \
  --i-table TC3_EBC2_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_EBC2_taxbarplot.qzv


#Control2


qiime feature-table filter-samples \
--i-table TC3_table.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "Control2='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_Control2_table.qza
 
qiime feature-table summarize \
--i-table TC3_Control2_table.qza \
--o-visualization TC3_Control2_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt
 
qiime taxa barplot \
  --i-table TC3_Control2_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_Control2_taxbarplot.qzv


# Decontam was run on RStudio for EBC1's 
# We have to remove the contaminants from the .txt file created 


qiime feature-table filter-features \
--i-table TC3_table.qza \
--p-exclude-ids \
--m-metadata-file ContaminantsToRemove_TC3_EBC1.txt \
--o-filtered-table decontam_table_TC3_EBC1.qza


qiime feature-table summarize \
--i-table decontam_table_TC3_EBC1.qza \
--o-visualization decontam_table_TC3_EBC1.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


############## REMOVING SINGELTONS AND SAMPLES WITH LOW READS ############


# Removing singletons that have been created from removing contaminants before samples with low reads


qiime feature-table filter-features \
--i-table decontam_table_TC3_EBC1.qza  \
--p-min-frequency 2 \
--o-filtered-table final_decontam_table_TC3_EBC1.qza


qiime feature-table summarize \
--i-table final_decontam_table_TC3_EBC1.qza  \
--o-visualization final_decontam_table_TC3_EBC1.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


# Decontam was run on RStudio for Control2's 
# We have to remove the contaminants from the .txt file created 


qiime feature-table filter-features \
--i-table final_decontam_table_TC3_EBC1.qza \
--p-exclude-ids \
--m-metadata-file ContaminantsToRemove_TC3_Control2.txt \
--o-filtered-table decontam_table_TC3_Control2.qza


qiime feature-table summarize \
--i-table decontam_table_TC3_Control2.qza \
--o-visualization decontam_table_TC3_Control2.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


############## REMOVING SINGELTONS AND SAMPLES WITH LOW READS ############


# Removing singletons that have been created from removing contaminants before samples with low reads


qiime feature-table filter-features \
--i-table decontam_table_TC3_Control2.qza  \
--p-min-frequency 2 \
--o-filtered-table final_decontam_table_TC3_Control2.qza


qiime feature-table summarize \
--i-table final_decontam_table_TC3_Control2.qza  \
--o-visualization final_decontam_table_TC3_Control2.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


#Run Core diversity results and investigate ControlvsBiological


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny RCM_rooted-tree.qza \
  --i-table final_decontam_table_TC3_Control2.qza \
  --p-sampling-depth 2 \
  --m-metadata-file TC3_metadatav2.txt \
  --output-dir TC3_Control2_CoreDiversity_Results


qiime diversity beta-group-significance \
 --i-distance-matrix TC3_Control2_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
 --m-metadata-column ControlvsBiological\
 --m-metadata-file TC3_metadatav2.txt \
 --o-visualization TC3_Control2_CoreDiversity_Results/unweighted_unifrac_significance_ControlvsBiological.qzv


#Beta diversity
#BiologicalvsControl


qiime diversity beta-group-significance \
  --i-distance-matrix TC3_Control2_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column ControlvsBiological \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_Control2_CoreDiversity_Results/unweighted_unifrac_significance_BiologicalvsControl.qzv




#Filter samples by donors and their timepoints 


#Donor 89 (all timepoints) 


qiime feature-table filter-samples \
--i-table final_decontam_table_TC3_Control2.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "Donor_89='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_89_table.qza
 
qiime feature-table summarize \
--i-table TC3_89_table.qza \
--o-visualization TC3_89_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


#Donor 89 D0vsD3


qiime feature-table filter-samples \
--i-table final_decontam_table_TC3_Control2.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "Donor_89_D0vsD3='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_Donor_89_D0vsD3_table.qza
 
qiime feature-table summarize \
--i-table TC3_Donor_89_D0vsD3_table.qza \
--o-visualization TC3_Donor_89_D0vsD3_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


#Donor 89 D0vsD7


qiime feature-table filter-samples \
--i-table final_decontam_table_TC3_Control2.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "Donor_89_D0vsD7='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_Donor_89_D0vsD7_table.qza
 
qiime feature-table summarize \
--i-table TC3_Donor_89_D0vsD3_table.qza \
--o-visualization TC3_Donor_89_D0vsD7_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


#Donor 89 D0vsD10


qiime feature-table filter-samples \
--i-table final_decontam_table_TC3_Control2.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "Donor_89_D0vsD10='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_Donor_89_D0vsD10_table.qza
 
qiime feature-table summarize \
--i-table TC3_Donor_89_D0vsD10_table.qza \
--o-visualization TC3_Donor_89_D0vsD10_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt




#Run Corediversity results for Donor 89 (all timepoints)


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny RCM_rooted-tree.qza \
  --i-table TC3_89_table.qza \
  --p-sampling-depth 38058 \
  --m-metadata-file TC3_metadatav2.txt \
  --output-dir TC3_83_CoreDiversity_Results


qiime diversity beta-group-significance \
 --i-distance-matrix TC3_89_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
 --m-metadata-column ControlvsBiological \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_Control2_CoreDiversity_Results/unweighted_unifrac_significance_ControlvsBiological.qzv


#Run Corediversity results for Donor 89 (D0vsD3)


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny RCM_rooted-tree.qza \
  --i-table TC3_Donor_89_D0vsD3_table.qza \
  --p-sampling-depth 38058 \
  --m-metadata-file TC3_metadatav2.txt \
  --output-dir TC3_Donor_89_D0vsD3_CoreDiversity_Results


qiime diversity beta-group-significance \
 --i-distance-matrix TC3_Donor_89_D0vsD3_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
 --m-metadata-column Donor_89_D0vsD3 \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_Donor_89_D0vsD3_CoreDiversity_Results/unweighted_unifrac_significance


qiime diversity alpha-rarefaction \
  --i-table TC3_Donor_89_D0vsD3_table.qza \
  --i-phylogeny RCM_rooted-tree.qza \
  --p-max-depth 38058 \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_Donor_89_D0vsD3_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC3_Donor_89_D0vsD3_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_Donor_89_D0vsD3_CoreDiversity_Results/observed_features_significance.qzv






#Run Corediversity results for Donor 89 (D0vsD7)


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny RCM_rooted-tree.qza \
  --i-table TC3_Donor_89_D0vsD7_table.qza \
  --p-sampling-depth 38058 \
  --m-metadata-file TC3_metadatav2.txt \
  --output-dir TC3_Donor_89_D0vsD7_CoreDiversity_Results


qiime diversity beta-group-significance \
 --i-distance-matrix TC3_Donor_89_D0vsD7_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
 --m-metadata-column Donor_89_D0vsD7 \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_Donor_89_D0vsD7_CoreDiversity_Results/unweighted_unifrac_significance


#Run Corediversity results for Donor 89 (D0vsD10)


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny RCM_rooted-tree.qza \
  --i-table TC3_Donor_89_D0vsD10_table.qza \
  --p-sampling-depth 38058 \
  --m-metadata-file TC3_metadatav2.txt \
  --output-dir TC3_Donor_89_D0vsD10_CoreDiversity_Results


qiime diversity beta-group-significance \
 --i-distance-matrix TC3_Donor_89_D0vsD10_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
 --m-metadata-column Donor_89_D0vsD10 \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_Donor_89_D0vsD10_CoreDiversity_Results/unweighted_unifrac_significance


#unweighted unifrac emperor plots were empty for all 
#because only one sample was present for each time time point
#and no duplicates 
#Therefore beta diversity metric did not run 


#Run alpha diversity metric 
qiime diversity alpha-rarefaction \
  --i-table TC3_89_table.qza \
  --i-phylogeny RCM_rooted-tree.qza \
  --p-max-depth 38058 \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_89_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC3_89_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_89_CoreDiversity_Results/observed_features_significance.qzv


#^Run alpha diversity metric did not work 


#Run tax barplot for donor 89 (all timepoints)


qiime taxa barplot \
  --i-table TC3_89_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_Donor_89_Taxonomy_BarPlots.qzv




#Run tax barplot for all donors across all timepoints 
#Use ppt and arrange D0 of all donors, D3 of all donors and so on 
#for easier interpretation


#Tax barplots for all donors across all timepoints
#Filter samples first


qiime feature-table filter-samples \
--i-table final_decontam_table_TC3_Control2.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "Day='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_Day_table.qza
 
qiime feature-table summarize \
--i-table TC3_Day_table.qza \
--o-visualization TC3_Day_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


#tax barplot 


qiime taxa barplot \
  --i-table TC3_Day_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_Day_Taxonomy_BarPlots.qzv


#Ran core metrics and alpha significance on column Day


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny RCM_rooted-tree.qza \
  --i-table TC3_Day_table.qza \
  --p-sampling-depth 36793 \
  --m-metadata-file TC3_metadatav2.txt \
  --output-dir TC3_Day_CoreDiversity_Results
#Alpha rarefaction and significance, 
#beta metrics and maaslin file prep


qiime diversity beta-group-significance \
  --i-distance-matrix TC3_Day_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column Day\
  --m-metadata-file TC3_metadatav2.txt \
  --p-pairwise \
  --o-visualization TC3_Day_CoreDiversity_Results/unweighted_unifrac_significance_TC3_Day.qzv


qiime diversity alpha-rarefaction \
  --i-table TC3_Day_table.qza \
  --i-phylogeny RCM_rooted-tree.qza \
  --p-max-depth 36793 \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_Day_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC3_Day_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_Day_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC3_Day_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC3_Day-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC3_Day-table-L7.qza \
--o-relative-frequency-table TC3_Day-frequency-table-L7.qza \
--output-dir TC3_Day-frequency-L7/


qiime tools export \
--input-path TC3_Day-frequency-table-L7.qza \
--output-path TC3_Day-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC3_Day-frequency-L7/feature-table.biom \
-o TC3_Day-frequency-L7/TC3_Day-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv








#make new metadata columns as D0vsD3, D0vsD7, D0vsD10
# D3vsD7, D3vsD10 and D7vsD10 headers. 
#Filter samples for the headers
#Run core metrics, beta and alpha diversity metrics 


#Filtering samples first 


qiime feature-table filter-samples \
--i-table final_decontam_table_TC3_Control2.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "D0vsD3='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_D0vsD3_table.qza
 
qiime feature-table summarize \
--i-table TC3_D0vsD3_table.qza \
--o-visualization TC3_D0vsD3_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt




qiime feature-table filter-samples \
--i-table final_decontam_table_TC3_Control2.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "D0vsD7='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_D0vsD7_table.qza
 
qiime feature-table summarize \
--i-table TC3_D0vsD7_table.qza \
--o-visualization TC3_D0vsD7_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt




qiime feature-table filter-samples \
--i-table final_decontam_table_TC3_Control2.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "D0vsD10='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_D0vsD10_table.qza
 
qiime feature-table summarize \
--i-table TC3_D0vsD10_table.qza \
--o-visualization TC3_D0vsD10_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt




qiime feature-table filter-samples \
--i-table final_decontam_table_TC3_Control2.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "D3vsD7='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_D3vsD7_table.qza
 
qiime feature-table summarize \
--i-table TC3_D3vsD7_table.qza \
--o-visualization TC3_D3vsD7_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


qiime feature-table filter-samples \
--i-table final_decontam_table_TC3_Control2.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "D3vsD10='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_D3vsD10_table.qza
 
qiime feature-table summarize \
--i-table TC3_D3vsD10_table.qza \
--o-visualization TC3_D3vsD10_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


qiime feature-table filter-samples \
--i-table final_decontam_table_TC3_Control2.qza \
--m-metadata-file TC3_metadatav2.txt \
--p-where "D7vsD10='NA'" \
--p-exclude-ids \
--o-filtered-table TC3_D7vsD10_table.qza
 
qiime feature-table summarize \
--i-table TC3_D7vsD10_table.qza \
--o-visualization TC3_D7vsD10_table.qzv \
--m-sample-metadata-file TC3_metadatav2.txt


#Core metrics, alpha beta diversity and prepping files 
#for maaslin 


#D0vsD3


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny RCM_rooted-tree.qza \
  --i-table TC3_D0vsD3_table.qza \
  --p-sampling-depth 36793 \
  --m-metadata-file TC3_metadatav2.txt  \
  --output-dir TC3_D0vsD3_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC3_D0vsD3_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column D0vsD3\
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D0vsD3_CoreDiversity_Results/unweighted_unifrac_significance_TC3_D0vsD3.qzv


qiime diversity alpha-rarefaction \
  --i-table TC3_D0vsD3_table.qza \
  --i-phylogeny RCM_rooted-tree.qza \
  --p-max-depth 36793 \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D0vsD3_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC3_D0vsD3_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D0vsD3_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC3_D0vsD3_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC3_D0vsD3-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC3_D0vsD3-table-L7.qza \
--o-relative-frequency-table TC3_D0vsD3-frequency-table-L7.qza \
--output-dir TC3_D0vsD3-frequency-L7/


qiime tools export \
--input-path TC3_D0vsD3-frequency-table-L7.qza \
--output-path TC3_D0vsD3-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC3_D0vsD3-frequency-L7/feature-table.biom \
-o TC3_D0vsD3-frequency-L7/TC3_D0vsD3-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv


#D0vsD7


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny RCM_rooted-tree.qza \
  --i-table TC3_D0vsD7_table.qza \
  --p-sampling-depth 36793 \
  --m-metadata-file TC3_metadatav2.txt  \
  --output-dir TC3_D0vsD7_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC3_D0vsD7_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column D0vsD7\
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D0vsD7_CoreDiversity_Results/unweighted_unifrac_significance_TC3_D0vsD7.qzv


qiime diversity alpha-rarefaction \
  --i-table TC3_D0vsD7_table.qza \
  --i-phylogeny RCM_rooted-tree.qza \
  --p-max-depth 36793 \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D0vsD7_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC3_D0vsD7_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D0vsD7_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC3_D0vsD7_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC3_D0vsD7-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC3_D0vsD7-table-L7.qza \
--o-relative-frequency-table TC3_D0vsD7-frequency-table-L7.qza \
--output-dir TC3_D0vsD7-frequency-L7/


qiime tools export \
--input-path TC3_D0vsD7-frequency-table-L7.qza \
--output-path TC3_D0vsD7-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC3_D0vsD7-frequency-L7/feature-table.biom \
-o TC3_D0vsD7-frequency-L7/TC3_D0vsD7-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv


#D0vsD10


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny RCM_rooted-tree.qza \
  --i-table TC3_D0vsD10_table.qza \
  --p-sampling-depth 36793 \
  --m-metadata-file TC3_metadatav2.txt  \
  --output-dir TC3_D0vsD10_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC3_D0vsD10_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column D0vsD10\
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D0vsD10_CoreDiversity_Results/unweighted_unifrac_significance_TC3_D0vsD10.qzv


qiime diversity alpha-rarefaction \
  --i-table TC3_D0vsD10_table.qza \
  --i-phylogeny RCM_rooted-tree.qza \
  --p-max-depth 36793 \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D0vsD10_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC3_D0vsD10_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D0vsD10_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC3_D0vsD10_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC3_D0vsD10-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC3_D0vsD10-table-L7.qza \
--o-relative-frequency-table TC3_D0vsD10-frequency-table-L7.qza \
--output-dir TC3_D0vsD10-frequency-L7/


qiime tools export \
--input-path TC3_D0vsD10-frequency-table-L7.qza \
--output-path TC3_D0vsD10-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC3_D0vsD10-frequency-L7/feature-table.biom \
-o TC3_D0vsD10-frequency-L7/TC3_D0vsD10-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv


#D3vsD7


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny RCM_rooted-tree.qza \
  --i-table TC3_D3vsD7_table.qza \
  --p-sampling-depth 42078 \
  --m-metadata-file TC3_metadatav2.txt  \
  --output-dir TC3_D3vsD7_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC3_D3vsD7_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column D3vsD7\
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D3vsD7_CoreDiversity_Results/unweighted_unifrac_significance_TC3_D3vsD7.qzv


qiime diversity alpha-rarefaction \
  --i-table TC3_D3vsD7_table.qza \
  --i-phylogeny RCM_rooted-tree.qza \
  --p-max-depth 42078 \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D3vsD7_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC3_D3vsD7_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D3vsD7_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC3_D3vsD7_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC3_D3vsD7-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC3_D3vsD7-table-L7.qza \
--o-relative-frequency-table TC3_D3vsD7-frequency-table-L7.qza \
--output-dir TC3_D3vsD7-frequency-L7/


qiime tools export \
--input-path TC3_D3vsD7-frequency-table-L7.qza \
--output-path TC3_D3vsD7-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC3_D3vsD7-frequency-L7/feature-table.biom \
-o TC3_D3vsD7-frequency-L7/TC3_D3vsD7-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv




#D3vsD10




qiime diversity core-metrics-phylogenetic \
  --i-phylogeny RCM_rooted-tree.qza \
  --i-table TC3_D3vsD10_table.qza \
  --p-sampling-depth 37434 \
  --m-metadata-file TC3_metadatav2.txt  \
  --output-dir TC3_D3vsD10_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC3_D3vsD10_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column D3vsD10\
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D3vsD10_CoreDiversity_Results/unweighted_unifrac_significance_TC3_D3vsD10.qzv


qiime diversity alpha-rarefaction \
  --i-table TC3_D3vsD10_table.qza \
  --i-phylogeny RCM_rooted-tree.qza \
  --p-max-depth 37434 \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D3vsD10_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC3_D3vsD10_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D3vsD10_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC3_D3vsD10_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC3_D3vsD10-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC3_D3vsD10-table-L7.qza \
--o-relative-frequency-table TC3_D3vsD10-frequency-table-L7.qza \
--output-dir TC3_D3vsD10-frequency-L7/


qiime tools export \
--input-path TC3_D3vsD10-frequency-table-L7.qza \
--output-path TC3_D3vsD10-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC3_D3vsD10-frequency-L7/feature-table.biom \
-o TC3_D3vsD10-frequency-L7/TC3_D3vsD10-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv


#D7vsD10


qiime diversity core-metrics-phylogenetic \
  --i-phylogeny RCM_rooted-tree.qza \
  --i-table TC3_D7vsD10_table.qza \
  --p-sampling-depth 37434 \
  --m-metadata-file TC3_metadatav2.txt  \
  --output-dir TC3_D7vsD10_CoreDiversity_Results


qiime diversity beta-group-significance \
  --i-distance-matrix TC3_D7vsD10_CoreDiversity_Results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-column D7vsD10\
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D7vsD10_CoreDiversity_Results/unweighted_unifrac_significance_TC3_D7vsD10.qzv


qiime diversity alpha-rarefaction \
  --i-table TC3_D7vsD10_table.qza \
  --i-phylogeny RCM_rooted-tree.qza \
  --p-max-depth 37434 \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D7vsD10_CoreDiversity_Results/alpha_rarefaction.qzv


qiime diversity alpha-group-significance \
  --i-alpha-diversity TC3_D7vsD10_CoreDiversity_Results/observed_features_vector.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D7vsD10_CoreDiversity_Results/observed_features_significance.qzv


qiime taxa collapse \
  --i-table TC3_D7vsD10_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table TC3_D7vsD10-table-L7.qza


qiime feature-table relative-frequency \
--i-table TC3_D7vsD10-table-L7.qza \
--o-relative-frequency-table TC3_D7vsD10-frequency-table-L7.qza \
--output-dir TC3_D7vsD10-frequency-L7/


qiime tools export \
--input-path TC3_D7vsD10-frequency-table-L7.qza \
--output-path TC3_D7vsD10-frequency-L7/


#Convert biom to text file (for M)


biom convert \
-i TC3_D7vsD10-frequency-L7/feature-table.biom \
-o TC3_D7vsD10-frequency-L7/TC3_D7vsD10-frequency-table-L7.txt \
--header-key ‘taxonomy’ --to-tsv


#Only do maaslin for D0vsD3, D3vsD7 and D7vsD10
#Run tax barplots for D0vsD3, D3vsD7 and D7vsD10


#D0vsD3


qiime taxa barplot \
  --i-table TC3_D0vsD3_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D0vsD3_taxbarplot.qzv


#D3vsD7


qiime taxa barplot \
  --i-table TC3_D3vsD7_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D3vsD7_taxbarplot.qzv


#D7vsD10


qiime taxa barplot \
  --i-table TC3_D7vsD10_table.qza \
  --i-taxonomy RCM_taxonomy.qza \
  --m-metadata-file TC3_metadatav2.txt \
  --o-visualization TC3_D7vsD10_taxbarplot.qzv




















































































































