#!/usr/bin/env Rscript
################################################################################
## Title:         phenotypes_synthetic_data.R
## Description:   Create synthetic phenotype data set
## Author:        Anna Niehues
## Date created:  2022-05-18
## Email:         anna.niehues@radboudumc.nl
################################################################################
## Notes:
##
################################################################################

args <- commandArgs(trailingOnly = TRUE)

phenotypes_infile <- args[1]
synth_ids_infile <- args[2]
syntheticdata_outfile <- args[3]
number_of_synthetic_samples <- args[4]

# read phenotypic data
pheno_in <- read.csv(phenotypes_infile, row.names = 1)
vars_in <- colnames(pheno_in)
# convert to factor
pheno_in[, vars_in] <- lapply(pheno_in[, vars_in], as.factor)

# read synthetic ids file
synth_ids <- read.csv(synth_ids_infile)

# simple simulated data based on distribution of original data,
# not preserving correlations
synth_data <- as.data.frame(
    do.call(
        rbind,
        lapply(seq_len(number_of_synthetic_samples), function(idx) {
            apply(pheno_in, 2, function(column_values) {
                # take random samples from observed values
                sample(column_values, 1) }) })))
colnames(synth_data) <- colnames(pheno_in)
rownames(synth_data) <- synth_ids$XOmicsPhenoID

write.csv(synth_data, file = syntheticdata_outfile, row.names = TRUE)
