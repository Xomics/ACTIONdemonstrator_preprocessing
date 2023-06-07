#!/usr/bin/env Rscript
################################################################################
## Title:         add_tscores.R
## Description:   Add T scores (Aggression score) to NTR phenotype data
## Author:        Casper
## Date created:  2022-12-19
## Email:         casper.devisser@radboudumc.nl
################################################################################
## Notes:
##
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

# read command line arguments - input / output file names
args <- commandArgs(trailingOnly = TRUE)

phenotypes_infile <- args[1]
T_scores <- args[2]
output_file <- args[3]

# read input file to data frame
phenotypes_df <- load_pheno_data(phenotypes_infile)
T_scores_df <- load_pheno_data(T_scores)
phenotypes_df$Tca_agg_m_act  <- T_scores_df$Tca_agg_m_act


write.csv(phenotypes_df, file = output_file, row.names = FALSE)
