#!/usr/bin/env Rscript
################################################################################
## Title:         phenotypes_feature_selection.R
## Description:   Select phenotypic features for subsequent analyses
## Author:        Anna Niehues
## Date created:  2022-01-02
## Email:         anna.niehues@radboudumc.nl
################################################################################
## Notes:
## Input file can be one of the following:
## "Z:/Data/phenotypes/upload/NTR_2056_Jenny_van_Dongen_ActionDemonstrator_set2_20210202.sav"
## "Z:/Data/Upload20220609/ACTION_clinical_CuriumXomics.csv"
################################################################################

#' Read phenotype data
#'
#' @param dir path to pheno file
#' @return pheno data as dataframe
load_pheno_data <- function(infile) {
  require(tools)
  if (file_ext(infile) == "sav") {
    df <- foreign::read.spss(infile,
                             use.value.labels = FALSE,
                             to.data.frame = TRUE)
  } else { # "csv"
    df <- read.csv(infile)
  }
  df[, 1] <- gsub(" ", "", df[, 1]) #remove white space from XOmics IDs
  rownames(df) <- df$XOmicsPhenoID
  return(df)
}

#' Extract survey data from phenotype set
#' Data frame with individuals in rows with XOmicsPhenoID as rownames and
#' survey elements (mother-rated questions from ACTION) in columns
#'
#' @param df Phenotypes_set2 or 3 questions (questions function)
#' @return df phenotypes dataframe
extract_survey_question_data <- function(df, mapping_df) {
  num_CURIUMvars <- sum(names(df) %in% mapping_df$CURIUMvariable)
  num_NTRvars <- sum(names(df) %in% mapping_df$NTRvariable)
  if (num_CURIUMvars > num_NTRvars) {
    vars <- mapping_df[!is.na(mapping_df$CURIUMvariable),]
    df <- df[, vars$CURIUMvariable]
    names(df) <- vars$variable
  } else {
    vars <- mapping_df[!is.na(mapping_df$NTRvariable),]
    df <- df[, vars$NTRvariable]
    names(df) <- vars$variable
  }
  return(df)
}

# read command line arguments - input / output file names
args <- commandArgs(trailingOnly = TRUE)

variable_mapping_file <- args[1]
output_file <- args[2]
output_file_labels <- args[3]
phenotypes_infile1 <- args[4]
if (length(args[5]) > 4) {
  phenotypes_infile2 <- args[5]
}
# read local variable mapping file
mapping_df <- read.csv(variable_mapping_file) #"CBCL6-18_variables.csv"
# read input file to data frame
phenotypes_df <- load_pheno_data(phenotypes_infile1)
if (length(args[5]) > 4) {
  phenotypes_df <- cbind(phenotypes_df, load_pheno_data(phenotypes_infile2))
}
# extract variables corresponding to selected CBCL checklist questions
behaviordata_df <- extract_survey_question_data(phenotypes_df, mapping_df)
# Extract labels of variables of extracted survey data
behaviordata_df_labels <- data.frame(
  variable = names(behaviordata_df),
  label = mapping_df[mapping_df$variable %in% names(behaviordata_df), "label"]
)

write.csv(behaviordata_df, file = output_file, row.names = TRUE)
write.csv(behaviordata_df_labels, file = output_file_labels, row.names = TRUE)
