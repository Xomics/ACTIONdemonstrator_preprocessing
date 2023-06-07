#!/usr/bin/env nextflow


nextflow.enable.dsl=2

project_dir = projectDir




////////////////////////////////////////////////////
/* --        Behavioral data preparation        -- */
////////////////////////////////////////////////////+

process CBCL_PREPARATION {

	label 'r_base_small_tasks'

	publishDir "${params.output}/Data_preparation", mode: 'copy', overwrite: true
	
	input:
	path pheno2

	output:
	path 'cbcl_data.csv'
	path 'cbcl_labels.csv'

	"""
	Rscript --vanilla $project_dir/Scripts/cbcl_feature_selection.R $project_dir/Scripts/mapping_tables/CBCL6-18_variables.csv cbcl_data.csv cbcl_labels.csv ${pheno2}
	"""
}


////////////////////////////////////////////////////
/* --       Synthetic behavioral data set       -- */
////////////////////////////////////////////////////+

process CBCL_SYNTHETIC_DATA {

	label 'r_base_small_tasks'

	publishDir "${params.output}/Synthetic_data", mode: 'copy', overwrite: true

	input:
	path pheno
	path synth_ids
	val number_of_synthetic_samples

	output:
	path 'synthetic_cbcl_data.csv'

	"""
	Rscript --vanilla $project_dir/Scripts/cbcl_synthetic_data.R ${pheno} ${synth_ids} synthetic_cbcl_data.csv ${number_of_synthetic_samples}
	"""
}


