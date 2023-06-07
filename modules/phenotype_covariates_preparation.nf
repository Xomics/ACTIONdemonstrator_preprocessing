#!/usr/bin/env nextflow


nextflow.enable.dsl=2

project_dir = projectDir


////////////////////////////////////////////////////
/* --     Phenotypes covariates add T scores   -- */
////////////////////////////////////////////////////+

process PHENOTYPE_TSCORES {

	label 'r_base_small_tasks'

	input:
	path pheno2
	path T_scores

	output:
	path 'phenotypes_set2_Tscores.csv'

	"""
	Rscript $project_dir/Scripts/add_tscores.R ${pheno2} ${T_scores} 'phenotypes_set2_Tscores.csv'
	"""
}

////////////////////////////////////////////////////
/* --     Phenotypes covariates preparation     -- */
////////////////////////////////////////////////////+

process PHENOTYPECOVARIATES_PREPARATION {

	label 'r_base_small_tasks'

	input:
	path pheno2
	path pheno3

	output:
	path 'phenotype_covariates_data.csv'
	path 'phenotype_covariates_labels.csv'

	"""
	Rscript --vanilla $project_dir/Scripts/cbcl_feature_selection.R $project_dir/Scripts/mapping_tables/phenotype_covariates_variables.csv phenotype_covariates_data.csv phenotype_covariates_labels.csv ${pheno2} ${pheno3}
	"""
}



////////////////////////////////////////////////////
/* --       Phenotypes rewrite df values       -- */
////////////////////////////////////////////////////+

process PHENOTYPECOVARIATES_REWRITE {

	publishDir "${params.output}/Data_preparation", mode: 'copy', overwrite: true

	input:
	path pheno_covariates

	output:
	path 'phenotype_covariates_data_hr.csv'

	"""
	cp -L $project_dir/Scripts/covariates_rewrite.Rmd covariates_rewrite.Rmd
	Rscript -e "rmarkdown::render('covariates_rewrite.Rmd', output_format = 'html_document', output_file = 'covariates_rewrite.html',  params = list(covariates_path = '${pheno_covariates}', output_dir_csv = 'phenotype_covariates_data_hr.csv'))"
	"""
}



////////////////////////////////////////////////////
/* -- Synthetic phenotypes covariates data set  -- */
////////////////////////////////////////////////////+

process PHENOTYPECOVARIATES_SYNTHETIC_DATA {

	label 'r_base_small_tasks'

	publishDir "${params.output}/Synthetic_data", mode: 'copy', overwrite: true

	input:
	path pheno
	path synth_ids
	val number_of_synthetic_samples

	output:
	path 'synthetic_phenotype_covariates_data.csv'

	"""
	Rscript --vanilla $project_dir/Scripts/cbcl_synthetic_data.R ${pheno} ${synth_ids} synthetic_phenotype_covariates_data.csv ${number_of_synthetic_samples}
	"""
}


