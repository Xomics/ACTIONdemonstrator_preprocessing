#!/usr/bin/Rscript

################################################################################
## Title:         metabolomics_QC.R
## Description:   Sample level QC data
## Author:        Casper de Visser, René Pool
## Date created:  2022-02-02
## Email:         casper.devisser@radboudumc.nl
################################################################################
## Notes:
##
################################################################################


#Functions


#' Performs a sample level QC based on parameters recorded in phenotypes_set2
#'
#' @param metabolomics_values_df dataframe containing the metabolomic data
#' @param phenotypes_set2_df dataframe containing the set2 phenotype data
#' @param IDs_df dataframe containing the subject IDs for merging purposes
#' @return QCFilterDF dataframe with TRUE/FALSE values for each QC criterion
qc_metabolomics_sample_level <- function(metabolomics_values_df,
                                         phenotypes_set2_df,
                                         IDs_df){

  # has column XOmicsPhenoID but not XOmicsmetaboID -> merge with IDs table
  PhenoSet2DF <- phenotypes_set2_df 
  tmp_columns <- names(PhenoSet2DF)
  PhenoSet2DF <- merge(x = PhenoSet2DF,
                       y = IDs_df[, c("XOmicsmetaboID", "XOmicsPhenoID")],
                       by = "XOmicsPhenoID",
                       all.x = TRUE)
  PhenoSet2DF <- PhenoSet2DF[, c("XOmicsmetaboID", tmp_columns)]
  remove(tmp_columns)
  # merge metabolomics and phenotypes tables
  MDF <- merge(x = metabolomics_values_df,
               y = PhenoSet2DF,
               by = "XOmicsmetaboID",
               all.x = TRUE)
  # dim(MDF)
  # nrow(MDF)

  # On page https://gitlab.cmbi.umcn.nl/x-omics-action-dataset/project-management/blob/develop/meetings/2021-01-08_data_analysis.md, the quality control criteria are listed. For convenience, the sample QC criteria are repeated below:
  #
  #   index 	parameter 	                  exclusion criteria
  #       0 	U1_Menstruation_general_act 	Y
  #       1 	U1_Timediff_act 	            >=2hr
  #       2 	U1_collection_remarks_act 	  if text reveals something extreme (didn't put the lid on the container,…)
  #       3 	DS_Leucocytes 	              above trace (presence indicates infection or bad sample collection)
  #       4 	DS_Nitrite 	                  positive high (indicates bacterial contamination)
  #       5 	DS_Proteines 	                above 0.3
  #       6 	DS_Glucose 	                  above trace
  #       7 	DS_Blood 	                    above trace (hemo or non-hemo)
  #       8 	U1_Q4_flu_act 	              consider excluding Y?
  #       9 	U1_Q3_inflammation_act 	      consider excluding Y?
  #      10 	q56g_vomit_m 	                if at time of collection, consider excluding 2?
  #      11 	q56f_tummy_m 	                if at time of collection, consider excluding 2?
  #      12 	U1_Q1_Health_act 	            investigate Y and consider excluding case-by-case
  #
  # For now, we do not exclude variables, but keep in mind that variable property RsdQc (c.f. ../Output/20200908_VariableDF.tsv) can be used to verify the quality of the metabolic trait.

  QCFilterDF <- data.frame(matrix(nrow = nrow(MDF), ncol = 0))
  QCFilterDF$XOmicsmetaboID <- MDF$XOmicsmetaboID
  QCFilterDF_variables = data.frame(matrix(ncol = 2, nrow = 0))
  names(QCFilterDF_variables) <- c("variable", "label")
  QCFilterDF_variables[1, ] = c("XOmicsmetaboID", "Metabolomics measurement ID")

  # Menstruation occurred (n=17), U1_Menstruation_general_act
  # "1" "2"
  # Is your daughter already menstruating? - urine collection 1 
  QCFilterDF$Menstruation <- (MDF$U1_Menstruation_general_act == 2)
  QCFilterDF[is.na(QCFilterDF$Menstruation), "Menstruation"] <- FALSE
  # table(QCFilterDF$Menstruation)
  QCFilterDF_variables[nrow(QCFilterDF_variables) + 1, ] = c(
    "Menstruation", "Menarche has already occurred")

  # Time between sample collection and sample freezing is >=1h(n=69);>=2h(n=35)
  # mean = 17 +- 34 min, max > 500 min
  # Difference between time urine at collection moment 1 was frozen and 
  # collected in minutes
  QCFilterDF$Specimen_at_RT <- (MDF$U1_Timediff_act >= 120)
  # table(QCFilterDF$Specimen_at_RT) 
  QCFilterDF_variables[nrow(QCFilterDF_variables) + 1, ] = c(
    "Specimen_at_RT", 
    "Time between urine specimen collection and freezing was more than 120 min")

  # Collection remarks indicate possible problem (n=13)
  # Do you have any other comments or things that we should know about the 
  # collection or storage of urine? - urine collection 1
  QCFilterDF$Problem_indicated <- grepl(pattern = "over 2 dagen verzameld",
                           x = MDF$U1_collection_remarks_act)
  QCFilterDF$Problem_indicated <- QCFilterDF$Problem_indicated | 
    grepl(pattern = "2 dagen verzameld", x = MDF$U1_collection_remarks_act)
  QCFilterDF$Problem_indicated <- QCFilterDF$Problem_indicated | 
    grepl(pattern = "op 2 dagen", x = MDF$U1_collection_remarks_act)
  QCFilterDF$Problem_indicated <- QCFilterDF$Problem_indicated | 
    grepl(pattern = "antibiotica", x = MDF$U1_collection_remarks_act)
  QCFilterDF$Problem_indicated <- QCFilterDF$Problem_indicated | grepl(
    pattern = "van tevoren gegeten en gedronken",
    x = MDF$U1_collection_remarks_act)
  QCFilterDF$Problem_indicated <- QCFilterDF$Problem_indicated | grepl(
    pattern = "geroerd met vork", x = MDF$U1_collection_remarks_act)
  QCFilterDF$Problem_indicated <- QCFilterDF$Problem_indicated | grepl(
    pattern = "lange tijd tussen urine collectie en invriezen",
    x = MDF$U1_collection_remarks_act)
  QCFilterDF$Problem_indicated <- QCFilterDF$Problem_indicated | grepl(
    pattern = "beide kinderen hebben dezelfde uritainer gebruikt",
    x = MDF$U1_collection_remarks_act)
  # table(QCFilterDF$Problem_indicated)
  QCFilterDF_variables[nrow(QCFilterDF_variables) + 1, ] = c(
    "Problem_indicated", 
    "Possible problem with specimen collection or storage has been indicated")

  # Leukocytes in urine (n=78)
  # "125++ positive" "15 trace"       "70+ positive"   "Negative"       
  # "no data"        "trace "
  QCFilterDF$Leukocytes <- (
    trimws(MDF$ACTIONBB23_DS_Leucocytes) == "70+ positive") |
    (trimws(MDF$ACTIONBB23_DS_Leucocytes) == "125++ positive")
  # table(QCFilterDF$Leukocytes)
  QCFilterDF_variables[nrow(QCFilterDF_variables) + 1, ] = c(
    "Leukocytes", 
    "Dipstick measurement shows that leukocyte level in urine specimen is above trace")
  
  # Nitrite in urine 
  # "Negative"       "no data"        "positive high " "positive low"
  QCFilterDF$Nitrite <- (trimws(MDF$ACTIONBB23_DS_Nitrite) == "positive high")
  # table(QCFilterDF$Nitrite)
  QCFilterDF_variables[nrow(QCFilterDF_variables) + 1, ] = c(
    "Nitrite", 
    "Dipstick measurement shows that nitrite level in urine specimen is high")
  
  # Proteines in urine (n=5)
  # "0.3 +"    "1  ++"    "Negative" "no data"  "trace"    "trace "
  QCFilterDF$Protein <- (trimws(MDF$ACTIONBB23_DS_Proteines) == "1  ++")
  # table(QCFilterDF$Protein)
  QCFilterDF_variables[nrow(QCFilterDF_variables) + 1, ] = c(
    "Protein", 
    "Dipstick measurement shows that protein level in urine specimen is high")
  
  # Glucose (n=10) TODO: keep "1 trace" ?
  # "1 trace  " "Negative"  "Negative " "no data"
  QCFilterDF$Glucose <- !(trimws(MDF$ACTIONBB23_DS_Glucose) %in% c(
    "Negative", "1 trace", "no data"))
  QCFilterDF_variables[nrow(QCFilterDF_variables) + 1, ] = c(
    "Glucose", 
    "Dipstick measurement shows that glucose level in urine specimen is above trace")
  
  # Blood in urine (n=11)
  # "10 trace hemo."     "10 trace Non-hemo." "25 + hemo."         "80 ++ hemo."        
  # "80 ++ Non-hemo."    "Negative Non-hemo." "no data"            "trace " 
  QCFilterDF$Blood <- (
    trimws(MDF$ACTIONBB23_DS_Blood) == '80 ++ Non-hemo.') |
    (trimws(MDF$ACTIONBB23_DS_Blood) == '25 + hemo.') |
    (trimws(MDF$ACTIONBB23_DS_Blood) == '80 ++ hemo.')
  # table(QCFilterDF$Blood)
  QCFilterDF_variables[nrow(QCFilterDF_variables) + 1, ] = c(
    "Blood", 
    "Dipstick measurement shows that blood level in urine specimen is above trace")
  
  # flu (n=20)
  # Does the child currently have a (childhood) disease such as (stomach)flue or chicken-pox? - urine collection 1
  QCFilterDF$Flu <- (MDF$U1_Q4_flu_act == 2)
  # table(QCFilterDF$Flu)
  QCFilterDF_variables[nrow(QCFilterDF_variables) + 1, ] = c(
    "Flu",
    "Child had a (childhood) disease such as (stomach)flue or chicken-pox at the urine specimen collection time")
  
  # inflammation (n=36)
  # Does the child currently have any infections (e.g., toothache, infected eye, urinary tract infection)? - urine collection 1
  QCFilterDF$Inflammation <- (MDF$U1_Q3_inflammation_act == 2)
  QCFilterDF_variables[nrow(QCFilterDF_variables) + 1, ] = c(
    "Inflammation",
    "Child had infection (e.g., toothache, infected eye, urinary tract infection) at the urine specimen collection time")
  
  # ? (n=57)
  # Does the child have a chronic physical condition or physical disability? - urine collection 1
  QCFilterDF$PhysicalHealth <- (MDF$U1_Q1_Health_act == 2)
  # table(QCFilterDF$Specimen_at_RT2)
  QCFilterDF_variables[nrow(QCFilterDF_variables) + 1, ] = c(
    "PhysicalHealth",
    "Child has chronic physical condition or physical disability")

  return(list(QCFilterDF, QCFilterDF_variables))
}

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
  

args = commandArgs(trailingOnly=TRUE)
#args = c(
#  "Z:/Data/metabolomics_and_biomarkers/upload/XOmics_NTR_ACTION_MtblmcsValues.tsv",
#  "Z:/Data/phenotypes/upload/NTR_2056_Jenny_van_Dongen_ActionDemonstrator_set2_20210202.sav",
#  "Z:/Data/IDs/ACTIONdemonstrator_XOmics_IDs_09022021.csv",
#  "out.csv"
#)

mtblmcs_values_path = args[1]
pheno2_path = args[2]
ids_path = args[3]

output_dir_values = args[4]
output_dir_variables = args[5]

# Read metabolomics filtered data
# Read metabolomics data
load_file <- function(infile) {
	require(tools)
	if (file_ext(infile) == "csv") {
		df <- read.csv(infile)
	} else if (file_ext(infile) == "tsv") {
		df <- read.csv(infile, sep = "\t")
	}
	return(df)
}

mtblcs_values <- load_file(mtblmcs_values_path)


# Read phenotype set2
phenotypes_set2 <- load_pheno_data(pheno2_path)

# Read IDs file
IDs <- read.table(ids_path, header = TRUE, sep = ",")

# Targets
metabolomics_qc_values_variables <- qc_metabolomics_sample_level(
  mtblcs_values, phenotypes_set2, IDs)

# Write to tsv
write.table(metabolomics_qc_values_variables[[1]], file = output_dir_values, sep = ",", 
            row.names = FALSE)
write.table(metabolomics_qc_values_variables[[2]], file = output_dir_variables, sep = ",", 
            row.names = FALSE)
