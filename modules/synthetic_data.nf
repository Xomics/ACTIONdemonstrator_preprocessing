#!/usr/bin/env nextflow


nextflow.enable.dsl=2

project_dir = projectDir


////////////////////////////////////////////////////
/* --         Synthetic sample IDs table       -- */
////////////////////////////////////////////////////+

process SYNTHETIC_IDS {

	label 'r_base_small_tasks'

	publishDir "${params.output}/Synthetic_data", mode: 'copy', overwrite: true

	input:
	val number_of_synthetic_samples

	output:
	path 'ACTIONdemonstrator_XOmics_IDs_synthetic.csv'

	"""
	Rscript --vanilla $project_dir/Scripts/create_synthetic_ids.R ${number_of_synthetic_samples} ACTIONdemonstrator_XOmics_IDs_synthetic.csv
	"""
}




////////////////////////////////////////////////////
/* --       Synthetic metabolomics data set       -- */
////////////////////////////////////////////////////+

process METABOLOMICS_SYNTHETIC_DATA {

	label 'r_base_small_tasks'

	publishDir "${params.output}/Synthetic_data", mode: 'copy', overwrite: true

	input:
	path mtblmcs_values
	path synth_ids
	val number_of_synthetic_samples

	output:
	path 'synthetic_metabolomics.csv'

	"""
	Rscript --vanilla $project_dir/Scripts/metabolomics_synthetic_data.R ${mtblmcs_values} ${synth_ids} synthetic_metabolomics.csv ${number_of_synthetic_samples}
	"""
}

////////////////////////////////////////////////////
/* --       Synthetic epigenomics data set       -- */
////////////////////////////////////////////////////+

process EPIGENOMICS_SYNTHETIC_DATA {

	label 'r_base_small_tasks'

	publishDir "${params.output}/Synthetic_data", mode: 'copy', overwrite: true

	input:
	path epigenomics_values
	path epigenomics_meta
	path synth_ids
	val number_of_synthetic_samples

	output:
	path 'synthetic_epigenomics.csv'
	path 'synthetic_epigenomics_meta.csv'

	"""
	Rscript --vanilla $project_dir/Scripts/epigenomics_synthetic_data.R ${epigenomics_values} ${synth_ids} synthetic_epigenomics.csv ${number_of_synthetic_samples}
	Rscript --vanilla $project_dir/Scripts/epigenomics_synthetic_data.R ${epigenomics_meta} ${synth_ids} synthetic_epigenomics_meta.csv ${number_of_synthetic_samples}
	"""
}

