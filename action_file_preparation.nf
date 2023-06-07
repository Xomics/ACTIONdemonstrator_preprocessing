#!/usr/bin/env nextflow


nextflow.enable.dsl=2

project_dir = projectDir

////////////////////////////////////////////////////
/*    --               Functions               -- */
////////////////////////////////////////////////////+


def helpMessage() {
  log.info """
        Workflow documentation can be found on https://gitlab.cmbi.umcn.nl/x-omics-action-dataset/action_nextflow/-/tree/main/Data_preparation

		Usage:
		To run the workflow with the NTR-ACTION cohort: 
		nextflow run action_file_preparation.nf 
			--output  /dir/of/choice
			--container_dir /mnt/workspace/Singularity/ 
			--mtblmcs_values /mnt/workspace/Data/metabolomics_and_biomarkers/upload/XOmics_NTR_ACTION_MtblmcsValues.tsv 
			--mtblmcs_variables /mnt/workspace/Data/metabolomics_and_biomarkers/upload/XOmics_NTR_ACTION_MtblmcsVariables.tsv 
			--mtblmcs_dictionary /mnt/workspace/Data/metabolomics_and_biomarkers/upload/ACTION_dictionary.xlsx 
			--phenotypes_set2 /mnt/workspace/Data/phenotypes/upload/NTR_2056_Jenny_van_Dongen_ActionDemonstrator_set2_20210202.sav 
			--phenotypes_set3 /mnt/workspace/Data/phenotypes/upload/NTR_2056_Jenny_van_Dongen_ActionDemonstrator_set3_20210202.sav 
			--epigenomics_values /mnt/workspace/Data/epigenetics/Drake_input_files/ACTION.EPIC.betas_NTR.csv
			--epigenomics_meta /mnt/workspace/Data/epigenetics/upload/ACTION.metadata_NTR_22092020.RData 
			--ids /mnt/workspace/Data/IDs/ACTIONdemonstrator_XOmics_IDs_09022021.csv 

		To run the workflow with the CURIUM cohort: 
		nextflow run action_file_preparation.nf 
			--output  /dir/of/choice
			--container_dir /mnt/workspace/Singularity/ 
			--mtblmcs_values /mnt/workspace/Data/CURIUM/20220429_PreqQC_ValuesDF_CuriumXomics.csv 
            --mtblmcs_variables   /mnt/workspace/Data/CURIUM/20220429/PreQC_VariableDF.csv
            --mtblmcs_sample_meta /mnt/workspace/Data/CURIUM/20220429_CuriumVariablesForMtblmcsQC_CuriumXomics.csv
            --mtblmcs_dictionary /mnt/workspace/Data/metabolomics_and_biomarkers/upload/ACTION_dictionary.xlsx #Same as for ACTION-NTR
            --phenotypes_set2 /mnt/workspace/Data/CURIUM/ACTION_clinical_CuriumXomics.csv
            --epigenomics_values /mnt/workspace/Data/CURIUM/ACTION.EPIC.betas_curium.csv
            --epigenomics_meta /mnt/workspace/Data/CURIUM/ACTION.metadata_Curium_23082022.Rdata
            --ids /mnt/workspace/Data/CURIUM/ACTIONdemonstrator_Curium_XOmics_IDs_09062022.csv 
			--curium

        Mandatory arguments:
         --output                       Directory where intermediate results will be stored
         --container_dir                The directory where the required Singularity (.sif files) images are stored

       Optional arguments:
         --synthetic_data	              If used, the workflow will generate and use synthetic data for analaysis. Default is 'false'.
         --synthetic_samples	          Number of synthetic samples to generate. Default is 100.
        """
}



////////////////////////////////////////////////////
/* --            Input data files              -- */
////////////////////////////////////////////////////+


mtblmcs_values = Channel.fromPath("${params.mtblmcs_values}")  
mtblmcs_dictionary = Channel.fromPath("${params.mtblmcs_dictionary}") 
mtblmcs_variables = Channel.fromPath("${params.mtblmcs_variables}") 
mtblmcs_sample_meta = Channel.fromPath("${params.mtblmcs_sample_meta}") 

phenotypes_set2 = Channel.fromPath("${params.phenotypes_set2}") 
phenotypes_set3 = Channel.fromPath("${params.phenotypes_set3}")
T_scores = Channel.fromPath("${params.T_scores}")

epigenomics_values = Channel.fromPath("${params.epigenomics_values}")  
epigenomics_meta = Channel.fromPath("${params.epigenomics_meta}")   

ids = Channel.fromPath("${params.ids}") 



////////////////////////////////////////////////////
/* --                  Modules                 -- */
////////////////////////////////////////////////////+


include { METABOLOMICS_SAMPLE_QC; METABOLOMICS_FEATURE_QC; METABOLOMICS_SAMPLE_QC_FILTER } from './modules/metabolomics_qc'
include { SYNTHETIC_IDS; METABOLOMICS_SYNTHETIC_DATA;  EPIGENOMICS_SYNTHETIC_DATA } from './modules/synthetic_data'
include { GENERATE_MAFS } from './modules/read_input_files'
include { METABOLOMICS_FILTERING} from './modules/metabolomics_preprocessing'
include { PHENOTYPE_TSCORES; PHENOTYPECOVARIATES_PREPARATION; PHENOTYPECOVARIATES_REWRITE; PHENOTYPECOVARIATES_SYNTHETIC_DATA } from './modules/phenotype_covariates_preparation'
include { CBCL_PREPARATION; CBCL_SYNTHETIC_DATA } from './modules/cbcl_preparation'



////////////////////////////////////////////////////
/* --                 Functions               -- */
////////////////////////////////////////////////////+


def group_maf_files(amines, oa, steroids) {

	maf_list = amines
			.join(oa)
			.join(steroids)

	maf_list = maf_list.collect()
	return(maf_list.minus([1]))
}



////////////////////////////////////////////////////
/* --                 Workflow                 -- */
////////////////////////////////////////////////////+


workflow {

	// Show help message
	if (params.help) {
    	helpMessage()
    	exit 0
	}
	
	////////////////
	// Create synthetic IDS table
	////////////////
	if (params.synthetic_data) {
    		SYNTHETIC_IDS(params.synthetic_samples)
	}

	////////////////
	// Metabolomics qc
	////////////////
	METABOLOMICS_FEATURE_QC(mtblmcs_values, mtblmcs_variables)
	if (!params.curium) {
		METABOLOMICS_SAMPLE_QC(mtblmcs_values, phenotypes_set2, ids)
	}
	if (params.curium) {
		METABOLOMICS_SAMPLE_QC(mtblmcs_values, mtblmcs_sample_meta, ids)
	}
	METABOLOMICS_SAMPLE_QC_FILTER(METABOLOMICS_FEATURE_QC.out, METABOLOMICS_SAMPLE_QC.out[0])
	

	// Use synthetic data
	if (params.synthetic_data) {
		METABOLOMICS_SYNTHETIC_DATA(METABOLOMICS_SAMPLE_QC_FILTER.out[1], SYNTHETIC_IDS.out, params.synthetic_samples)
		EPIGENOMICS_SYNTHETIC_DATA(epigenomics_values, epigenomics_meta, SYNTHETIC_IDS.out, params.synthetic_samples)
		GENERATE_MAFS(mtblmcs_dictionary, METABOLOMICS_SYNTHETIC_DATA.out)
	}

	// Use input data
	if (!params.synthetic_data) {
		GENERATE_MAFS(mtblmcs_dictionary, METABOLOMICS_SAMPLE_QC_FILTER.out[1])
	}
	
	maf_list = group_maf_files(GENERATE_MAFS.out)


	////////////////
	// Phenotypes and behavior data preparation and behavior data MCA
	////////////////
	if (!params.curium) {
		PHENOTYPE_TSCORES(phenotypes_set2, T_scores)
		PHENOTYPECOVARIATES_PREPARATION(PHENOTYPE_TSCORES.out, phenotypes_set3)
	}
	if (params.curium) {
	  PHENOTYPECOVARIATES_PREPARATION(phenotypes_set2, phenotypes_set3)
	}
	PHENOTYPECOVARIATES_REWRITE(PHENOTYPECOVARIATES_PREPARATION.out[0])
	if (params.synthetic_data) {
		PHENOTYPECOVARIATES_SYNTHETIC_DATA(PHENOTYPECOVARIATES_REWRITE.out, SYNTHETIC_IDS.out, params.synthetic_samples)
	}
	CBCL_PREPARATION(phenotypes_set2)
	if (params.synthetic_data) {
		CBCL_SYNTHETIC_DATA(CBCL_PREPARATION.out[0], SYNTHETIC_IDS.out, params.synthetic_samples)
	}

}
