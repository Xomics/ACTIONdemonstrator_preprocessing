#!/usr/bin/env nextflow


nextflow.enable.dsl=2

project_dir = projectDir


process GENERATE_MAFS {

	label 'r_base_analysis_small_tasks'

	if (!params.synthetic_data) {
		publishDir "${params.output}/Data_preparation", mode: 'copy', overwrite: true
	}
	if (params.synthetic_data) {
		publishDir "${params.output}/Synthetic_data", mode: 'copy', overwrite: true
	}

	input:
	path mtblmcs_dictionary
	path mtblmcs_values

	output:
	tuple val(1), path('amines_MAF.tsv')
	tuple val(1), path('OA_MAF.tsv')
	tuple val(1), path('steroids_MAF.tsv')

	"""
	Rscript $project_dir/Scripts/generate_MAF.R ${mtblmcs_dictionary} ${mtblmcs_values} amines_MAF.tsv OA_MAF.tsv steroids_MAF.tsv
	"""

}

