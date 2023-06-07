#!/usr/bin/env Rscript
################################################################################
## Title:         metabolomics_synthetic_data.R
## Description:   Create synthetic metabolomics data set
## Author:        Casper de Visser
## Date created:  2022-06-13
## Email:         Casper.deVisser@radboudumc.nl
################################################################################
## Notes:
##
################################################################################

args <- commandArgs(trailingOnly = TRUE)

metabolomics_infile <- args[1]
synth_ids_infile <- args[2]
syntheticdata_outfile <- args[3]
number_of_synthetic_samples <- args[4]

# read metabolomics data
mtblmcs_in <- read.csv(metabolomics_infile, row.names = 1)
vars_in <- colnames(mtblmcs_in)
# convert to factor
mtblmcs_in[, vars_in] <- lapply(mtblmcs_in[, vars_in], as.factor)

# read synthetic ids file
synth_ids <- read.csv(synth_ids_infile)


# Add noise to data with jitter()
data_num <- data.frame(lapply(mtblmcs_in[,1:95], function(x) as.numeric(as.character(x))))
data_num <- data.frame(lapply(data_num, jitter))
mtblmcs_in <- cbind(data_num, mtblmcs_in[,96:145])

# simple simulated data based on distribution of original data with added noise,
# not preserving correlations
synth_data <- as.data.frame(
  do.call(
    rbind,
    lapply(seq_len(number_of_synthetic_samples), function(idx) {
      apply(mtblmcs_in, 2, function(column_values) {
        sample(column_values, 1) }) })))
colnames(synth_data) <- colnames(mtblmcs_in)

synth_data$XOmicsmetaboID  <- synth_ids$XOmicsmetaboID
synth_data <- synth_data[ ,c(146, 1:145)]

write.csv(synth_data, file = syntheticdata_outfile, row.names = FALSE)
