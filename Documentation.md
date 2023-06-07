
# The ACTION workflow

## Metabolomics preparation

| Process | Parameters (value options) | Description | Input | Output |
|---------|----------------------------|-------------|-------|--------|
| `METABOLOMICS_FEATURE_QC` |  | Performs a metabolite QC based on parameters recorded in metabolomics variables file.  | Metabolomics values file, Metabolomics Variables file | `metabolomics_features_QC_filtered.csv` |
| `METABOLOMICS_SAMPLE_QC` |  | Performs a urine specimen QC based on parameters recorded in Phenotypes SPSS file, and dipstick measurements | Metabolomics values file, phenotypes SPSS file, IDs file | `metabolomics_qc_values.csv` (True means that QC parameter failed), `metabolomics_qc_variables.csv` |
| `METABOLOMICS_SAMPLE_QC_FILTER` |  | Remove samples with any TRUE values on the urine specimen QC file  | `metabolomics_features_QC_filtered.csv`, `metabolomics_qc_variables.csv` | `metabolomics_sample_QC.html`, `mtblmcs_values_QC.csv` |
| `METABOLOMICS_SYNTHETIC_DATA` |  `synthetic_samples` (Default = 100) | Process creates synthetic data set with a given number of samples based on distribution of values in original metabolomics data set. | `mtblmcs_values_QC.csv`, number of synthetic samples | `synthetic_metabolomics.csv`  |
| `GENERATE_MAFS`   |  | Generate Metabolite Assignment Files (MAF) for the different metabolomics platforms: amines, steroids and organic acids. EMBL-EBI guidelines on the MAF creation are followed (https://www.ebi.ac.uk/metabolights/guides/MAF/Title) | Metabolomics dictionary file, `mtblmcs_values_QC.csv`| `amines_MAF.tsv`, `OA_MAF.tsv`, `steroids_MAF.tsv` |

## Epigenomics preparation

| Process | Parameters (value options) | Description | Input | Output |
|---------|----------------------------|-------------|-------|--------|
| `EPIGENOMICS_SYNTHETIC_DATA` | `synthetic_samples` (Default = 100)  | Process creates synthetic data set with a given number of samples based on distribution of values in original epigenomics data and metadata. | epigenomics values, epigenomics_meta, number of synthetic samples | `synthetic_epigenomics.csv`, `synthetic_epigenomics_meta.csv`  |


## Phenotype / covariates data preparation

| Process | Parameters (value options) | Description | Input | Output |
|---------|----------------------------|-------------|-------|--------|
| `PHENOTYPECOVARIATES_PREPARATION` | | Process selects variables from ACTION (NTR, CURIUM) phenotypes data (.sav, .csv) and writes the selection to .csv file (individuals in rows, survey elements in columns). Additionally, a .csv file with labels of survey elements is created. | mapping table for variable selection `Scripts/mapping_tables/phenotype_covariates_variables.csv`, phenotypes SPSS file(s) or csv file | `phenotype_covariates_data.csv`, `phenotype_covariates_labels.csv` |
| `PHENOTYPECOVARIATES_SYNTHETIC_DATA` | `synthetic_samples` (Default = 100)  | Process creates synthetic data set with a given number of samples based on distribution of values in original phenotype data set. | `phenotype_covariates_data.csv`, number of synthetic samples | `synthetic_phenotype_covariates_data.csv` |

## CBCL data preparatio

| Process | Parameters (value options) | Description | Input | Output |
|---------|----------------------------|-------------|-------|--------|
| `CBCL_PREPARATION` | | Process selects mother-rated survey elements from ACTION phenotypes data (.sav) and writes the selection to .csv file (individuals in rows, survey elements in columns). Longitudinal survey data is not included. Additionally, a .csv file with labels of survey elements is created. | mapping table for variable selection `Scripts/mapping_tables/CBCL6-18_variables.csv`, phenotypes SPSS (.sav, NTR) or .csv (CURIUM) file | `cbcl_data.csv`, `cbcl_labels.csv` |
| `CBCL_SYNTHETIC_DATA` | `synthetic_samples` (Default = 100)  | Process creates synthetic data set with a given number of samples based on distribution of values in original phenotype data set. | `cbcl_data.csv`, number of synthetic samples | `synthetic_cbcl_data.csv` |

