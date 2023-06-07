#!/usr/bin/env Rscript
################################################################################
## Title:         epigenomics_synthetic_data.R
## Description:   Create synthetic epigenomics data set
## Author:        Casper de Visser
## Date created:  2022-06-13
## Email:         Casper.deVisser@radboudumc.nl
################################################################################
## Notes:
##
################################################################################

args <- commandArgs(trailingOnly = TRUE)

epigenomics_infile <- args[1]
synth_ids_infile <- args[2]
syntheticdata_outfile <- args[3]
number_of_synthetic_samples <- args[4]

# Read epigenomics data or metadata
# @param infile path to epigenomics data 
load_file <- function(infile) {
  require(tools)
  if (file_ext(infile) == "csv") {
    df <- read.csv(infile, row.names = 1)
    df <- t(df)
  } else if (file_ext(infile) == "RData") {
    load(infile)
    df <- metadata
  }
  return(df)
}

# Add jitter to numeric columns
add_jitter <- function(data) {
  if (file_ext(epigenomics_infile) == "csv") {
    data <- data.frame(lapply(data, function(x) as.numeric(as.character(x))))
    data <- data.frame(lapply(data, jitter))
    data[data<0] <- NA #remove values that are below 0
    data[data>1] <- NA # remove values that are above 1
  } else if (file_ext(epigenomics_infile) == "RData") {
    data_num <- data.frame(lapply(data[,17:25], function(x) as.numeric(as.character(x))))
    data_num <- data.frame(lapply(data_num, jitter))
    data <- cbind(data[,1:16], data_num)
  }
  return(data)
}


# Read in epigenomics data or metadata
epigenomics_in <- load_file(epigenomics_infile)
vars_in <- colnames(epigenomics_in)
# convert to factor
epigenomics_in <- data.frame(epigenomics_in)
epigenomics_in[, vars_in] <- lapply(epigenomics_in[, vars_in], as.factor)


# read synthetic ids file
synth_ids <- read.csv(synth_ids_infile)

# Add noise to data with jitter()
epigenomics_in <- add_jitter(epigenomics_in)


# simple simulated data based on distribution of original data with added noise,
# not preserving correlations
synth_data <- as.data.frame(
  do.call(
    rbind,
    lapply(seq_len(number_of_synthetic_samples), function(idx) {
      apply(epigenomics_in, 2, function(column_values) {
        sample(column_values, 1) }) })))
colnames(synth_data) <- colnames(epigenomics_in)
rownames(synth_data) <- synth_ids$XOmicsMethylID


# Transform rows and column if data is beta values
if (file_ext(epigenomics_infile) == "csv") {
  synth_data <- t(synth_data)
}

write.csv(synth_data, file = syntheticdata_outfile, row.names = TRUE)
