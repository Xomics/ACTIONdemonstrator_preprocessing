#!/usr/bin/Rscript

################################################################################
## Title:         metabolomics_boExcludeRsdQC.R
## Description:   Metabolite level QC data
## Author:        Casper de Visser
## Date created:  2022-08-18
## Email:         casper.devisser@radboudumc.nl
################################################################################
## Notes:
##
################################################################################


#Functions


#' Performs a feature level QC based on boExdludeRSQC column
#'
#' @param values dataframe containing the metabolomic data
#' @param variables dataframe containing metabolomics metadata
#' @return values_sub dataframe with metabolites that passed boExcludeRsQC
metabolites_boExcludeRsdQC <- function(values, variables) {

  #separate bio and dipstick
  variables_sub <- variables[variables$platform != 'bio' & variables$platform != 'DS',]
  variables_bio_ds <- variables[variables$platform == 'bio'| variables$platform == 'DS',]

  #subset df on  metabolites with '0' score for boExdludeRsdQC
  variables_sub <- variables[variables$boExcludeRsdQc == 0, ]  
  variables_keep <- rbind(variables_sub, variables_bio_ds)
  metabolites_to_keep <- variables_keep$metabolite_dfname
    
  #subset values df on these metabolites
  names_sub <- names(values)[names(values) %in% metabolites_to_keep]

  values_sub <- values[, names_sub]
  return(values_sub)

}



# Read input data

args = commandArgs(trailingOnly=TRUE)
#args = c(
#  "Z:/Data/metabolomics_and_biomarkers/upload/XOmics_NTR_ACTION_MtblmcsValues.tsv",
#  "Z:/Data/metabolomics_and_biomarkers/upload/XOmics_NTR_ACTION_MtblmcsVariables.tsv",
#  "out.csv"
#)

mtblmcs_values_path = args[1]
mtblmcs_variables_path = args[2]

output_dir = args[3]


# Read metabolomics data
load_file <- function(infile, rows_value) {
	require(tools)
	if (file_ext(infile) == "csv") {
		df <- read.csv(infile, row.names=rows_value)
	} else if (file_ext(infile) == "tsv") {
		df <- read.csv(infile, sep = "\t", row.names=rows_value)
	}
	return(df)
}

mtblcs_values <- load_file(mtblmcs_values_path, 1)

mtblcs_variables <- load_file(mtblmcs_variables_path, NULL)


# Perform QC
metabolites_features_filtered <- metabolites_boExcludeRsdQC(mtblcs_values, mtblcs_variables)


# Add MetaboID column
metabolites_features_filtered$XOmicsmetaboID <- rownames(metabolites_features_filtered)
n_col <- ncol(metabolites_features_filtered)
metabolites_features_filtered <- metabolites_features_filtered[ , c(n_col, 1:(n_col-1))]

# Write to csv
write.csv(metabolites_features_filtered, output_dir, row.names = TRUE)

