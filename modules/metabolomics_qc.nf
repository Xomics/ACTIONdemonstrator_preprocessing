#!/usr/bin/env nextflow


nextflow.enable.dsl=2

project_dir = projectDir


process METABOLOMICS_SAMPLE_QC {

	label 'r_base_small_tasks'

	input:
	path mtblmcs_values
	path pheno2
	path ids

	output:
	path 'metabolomics_qc_values.csv'
	path 'metabolomics_qc_variables.csv'
	"""
	Rscript $project_dir/Scripts/metabolomics_QC.R  ${mtblmcs_values} ${pheno2} ${ids} metabolomics_qc_values.csv metabolomics_qc_variables.csv
	"""

}


process METABOLOMICS_SAMPLE_QC_FILTER {

	publishDir "${params.output}/Data_preparation", mode: 'copy', overwrite: true

	input:
	path mtblmcs_values
	path mtblmcs_QC_table

	output:
	path 'metabolomics_sample_QC.html' 
	path 'mtblmcs_values_QC.csv'

	"""
	cp -L $project_dir/Scripts/metabolomics_sample_QC.Rmd metabolomics_sample_QC.Rmd
  
	Rscript -e "rmarkdown::render('metabolomics_sample_QC.Rmd', output_format = 'html_document', output_file = 'metabolomics_sample_QC.html',  params = list(mtblmcs_values_path = '${mtblmcs_values}', sample_qc_path = '${mtblmcs_QC_table}', output_dir_csv = 'mtblmcs_values_QC.csv'))"
	"""

}


process METABOLOMICS_FEATURE_QC {

	label 'r_base_small_tasks'

	input:
	path mtblmcs_values
	path mtblmcs_variables
  
	output:
	path 'metabolomics_features_QC_filtered.csv'
  
	"""
	Rscript $project_dir/Scripts/metabolomics_boExcludeRsdQC.R  ${mtblmcs_values} ${mtblmcs_variables} metabolomics_features_QC_filtered.csv
	"""


}
