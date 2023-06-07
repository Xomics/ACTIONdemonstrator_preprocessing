################################################################################
## Title:        generate_MAF.R
## Description:  Create MAF-files from the Mtblmcs_values and Mtblmcs_dictionary files
##
## Author:       Casper de Visser
## Date created: 2022-04-13
## Email:        casper.devisser@radboudumc.nl
################################################################################
## Notes:
################################################################################

# Read in data

args = commandArgs(trailingOnly = TRUE)

dictionary_path <- args[1]
values_path <- args[2]

dictionary <- readxl::read_excel(dictionary_path)
values <- read.csv(values_path, sep = ',')

# Output directories

amines_MAF <- args[3]
OA_MAF <- args[4]
steroids_MAF <- args[5]


# Define constants
OLD_COLNAMES <- c('ChEBI_ID', "SMILES (isomeric where available)", "InChI Code", "short metabolite name", "HMDB_ID", "PubChem_CID", "KEGG_ID", "METLIN_ID")
CORRECT_COLNAMES <- c('database_identifier',  'smiles', 'InChI Code'	,'metabolite_identification',	'HMDB_ID',	'PubChem_CID',	'KEGG_ID', 'METLIN_ID')
METABOLOMICS_PLATFORMS <- c('amines', 'OA', 'steroids')
METABOLOMICS_PLATFORMS2 <- c('amines', 'organic acids', 'steroids')


prepare_dictionary <- function(dictionary, platform_string) {
  metabolite_names <- colnames(values)[2:ncol(values)]
  dictionary <- subset(dictionary, subset = dictionary$column %in% metabolite_names)
  
  # Subset specific platform
  platform_subset <- dictionary[dictionary$platform == platform_string,]
  
  # Subset relevant columns
  platform_subset <- platform_subset[, OLD_COLNAMES]
  
  #Change to correct column names
  colnames(platform_subset) <- CORRECT_COLNAMES
  
  #Add empty column for 'chemical_formula'
  platform_subset$chemical_formula <- NA
  platform_subset <- platform_subset[,c(1,9,2:8)]
  
  #Add 'CHEBI:' to all database_identifer numbers in column 1
  platform_subset$database_identifier <- lapply(platform_subset$database_identifier, function(x) paste0('CHEBI:', x))
  
  return(platform_subset)
  
}



# Separate values into different platforms
prepare_values <- function(values, string) {
  subset <-  values[, grepl(paste0(string, '|XOmicsmetaboID'), colnames(values))]
  rownames(subset) <- subset[,1]
  subset[,1] <- NULL
  subset <- t(subset)
  rownames(subset) <- NULL
  return(subset)
}

dictionary_subset <- lapply(METABOLOMICS_PLATFORMS2, function(x) prepare_dictionary(dictionary, x))
values_subsets <- lapply(METABOLOMICS_PLATFORMS, function(x) prepare_values(values, x))

# Concatenate dictionary and values for each, completing MAF
amines_final <- cbind(dictionary_subset[[1]], values_subsets[[1]])
OA_final <- cbind(dictionary_subset[[2]], values_subsets[[2]])
steroids_final <- cbind(dictionary_subset[[3]], values_subsets[[3]])


amines_final <- apply(amines_final,2,as.character)
OA_final <- apply(OA_final,2,as.character)
steroids_final <- apply(steroids_final,2,as.character)


# Write files to .tsv files
write.table(amines_final, file = amines_MAF, sep = "\t", row.names=FALSE )
write.table(OA_final, file = OA_MAF , sep = "\t", row.names=FALSE)
write.table(steroids_final, file = steroids_MAF, sep = "\t", row.names=FALSE )
