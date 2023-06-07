#!/usr/bin/env Rscript
################################################################################
## Title:         create_synthetic_ids.R
## Description:   Create synthetic sample IDs table
## Author:        Casper de Visser
## Date created:  2022-12-05
## Email:         Casper.deVisser@radboudumc.nl
################################################################################
## Notes:
##
################################################################################

# Params
args = commandArgs(trailingOnly=TRUE)

number_of_synthetic_samples <- args[1]
synthetic_ids_outfile <- args[2]


# Get list of 1 to number of synthetic samples (default = 100)
numbers <- sprintf('%00.3d', 1:number_of_synthetic_samples)


# Create vectors of IDs and dataframe
XOmicsPhenoID <- paste0('synth_XOP_', numbers)
XOmicsGenoID <- paste0('synth_XOG_', numbers)
XOmicsFamID <- paste0('synth_XOF_', numbers)
XOmicsMethylID <- paste0('synth_XOE_', numbers)
XOmicsmetaboID <- paste0('synth_XOM_', numbers)

df <- data.frame(XOmicsPhenoID, XOmicsGenoID, XOmicsFamID, XOmicsMethylID, XOmicsmetaboID)


# Write to csv
write.csv(df, synthetic_ids_outfile, row.names =  FALSE)
