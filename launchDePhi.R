
#launchDePhi.R Info ----
# Script to launch the decryption and de identification of the files present in the folder DATA_1
# The script operates per subfolder. This piece of code is not intended to be shared over the network.
# The scrip is meant to be launched on the top level.
#
# Antoine Lizee & Wendy Tang @ UCSF 09/14
# antoine.lizee@gmail.com

rm(list = ls())


# Initialization and parameters -------------------------------------------

library(plyr)
library(readr)

modeIsDefault <- "US"
# Do one at a time, seperately: "S" for Structured, "US" for unstructured.
# Get the environment variable if launch from bash.
modeIs <- switch(Sys.getenv("R_DEPHI_MODE"),
                 "STRUCTURED" = {cat("Launching for Structured data, from env variable"); "S"},
                 "UNSTRUCTURED" = {cat("Launching for Unstructured data, from env variable"); "US"},
                 {cat("Using script default, launching in mode", modeIsDefault); modeIsDefault}) 

date_shift_constant <- T        #T or F and must be consistent with Perl Config file
offset_days <- 105  #unique integer generated each time and must be consistent with Perl Config File
keep_note_update <- F    #Note update determined by columns note_id and note_csn_id
#Latest version of the note is the largest note_csn_id per note_id
#If this assumption does not hold, set parameter to T
perl_test_run <- F       #Set to F for all rows to be run in the deid-software
#T defaults to test run of 100 rows
rid_carbon_copies <- T   #Set to T if carbon copies are eliminated before de-identification
#Carbon copy text mostly contains identifiers and can cut down substantially on de-id software
#file_names <- c("RITM0032128_UCSF_Labs_20140725_encrypted.xlsx",   #file name of labs, meds, note file in that order w/ file extention
#               "RITM0032128_UCSF_Med_20140725_encrypted.xlsx",
#              "RITM0032128_UCSF_Notes_20140725_encrypted.xlsx") 


# Files Setup -------------------------------------------------------------

sheetNames <- c("Demographics", "Diagnosis", "LAB", "Medications") 
names(sheetNames) <- sheetNames
sheetNamesExport <- c(sheetNames, "Notes_text")      
# Input .rpts
baseFileName <- "%s.rpt"
fileNames <- sprintf(baseFileName, sheetNames)
names(fileNames) <- sheetNames
# Output csvs
baseExportFileName <- "%s.csv"
fileExportNames <- sprintf(baseExportFileName, sheetNamesExport)
names(fileExportNames) <- sheetNamesExport
fileExportNames["Diagnosis"] <- "Dx.csv"
fileExportNames["LAB"] <- "Labs.csv"
fileExportNames["Medications"] <- "Meds.csv"

project <- "Dataset_Name" # SAme name as the one of folder in Files_Stored and Files_Output folders
inputPath <- file.path("Files_Stored", project, "")
perl_env <- "deid-1.1"
codePath <- "Code"
stopifnot(all(sapply(c(codePath, inputPath, perl_env), file.exists)) ) # Check that the path is right
outputPath <- file.path("Files_Output", project, "")
dir.create(path = outputPath, showWarnings = F)


# Helpers -----------------------------------------------------------------

readRPT <- function(name, fileName = fileNames[name], ...) {

  cat("## Reading", fileName, "...\n")
  res <- suppressWarnings(read_delim(file.path(inputPath, fileName), quote = "", delim = "\t"))
  pbs <- problems(res)
  cat(sprintf("# %d problems looking like:\n", nrow(pbs)))
  print(head(pbs))
  cat(sprintf("# %d unique problems:\n", nrow(pbsU <- unique(pbs[-1]))))
  print(head(pbsU), 20)
  resNoNA <- na.omit(res)
  na_n <- nrow(res) - nrow(resNoNA)
  cat(sprintf("Removed %d lines (%.2f%%) with NA.\n-------\n", na_n, na_n / nrow(res) * 100))
  return(resNoNA)
}

writeCSV <- function(df, name) {
  write_csv(x = df, path = file.path(outputPath,fileExportNames[name]))
}


# Unstructured data -------------------------------------------------------

if (modeIs == "US") {
  
  #Read and prepare files
  cat("\n\n## Unstructured data ###\n")
  cat("########################\n")
  
  preparedUnstructuredTablesFilePath <- file.path(outputPath, "preparedUnstructuredTables.RData")
  unstructuredTableNames <- c("notes")
  
  if (file.exists(preparedUnstructuredTablesFilePath)) {
    cat("\n## 0102 - Loading files...###\n")
    load(preparedUnstructuredTablesFilePath)
    cat("# Done.\n")
  } else {
    
    ## Read in the tables  
    cat("\n## 01 - Reading tables...###\n")
    NOTES <- list()
    note_files <- dir(path = inputPath, pattern = "Notes_text")
    for (i in 1:length(note_files)) {
      NOTES[[i]] <- readRPT(fileName = note_files[i])
    }
    notes <- do.call(rbind, NOTES)
    
    ## Prepare the tables
    cat("\n## 02 - Preparing tables...###\n")
    #performs fixes on inconsistencies from excel files
    #reduces redundency from Notes
    source(file.path(codePath,"EMR_Prep_Unstructured.R"))
    
    save(list = unstructuredTableNames, file = preparedUnstructuredTablesFilePath)
  }
  
  #De-identification
  cat("\n## De-identification of Unstructured data###\n")
  
  deIdUnstructuredTablesFilePath <- file.path(outputPath, "deIdUnstructuredTables.RData")
  
  if (file.exists(deIdUnstructuredTablesFilePath)) {
    cat("## 0304 - Loading files...###\n")
    load(preparedUnstructuredTablesFilePath)
    cat("# Done.")
  } else {
    
    #in notes file, shifts dates in structured field
    cat("\n## 03 - Deidentification of Structured Fields...###\n")
    source(file.path(codePath,"EMR_Deid_Functions.R"))
    source(file.path(codePath,"EMR_Deid_Unstructured.R"))
    
    # Run Perl Deid
    cat("\n## 04 - Deidentification of Notes (free text)...###\n")
    source(file.path(codePath,"EMR_Perl.R"))
    
    save(list = unstructuredTableNames, file = deIdUnstructuredTablesFilePath)
  }
  
  #Export files
  cat("\n## 05 - Exporting tables...###\n")
  writeCSV(notes, "Notes_text")

}

# Structured data ---------------------------------------------------------

if (modeIs == "S") {
  
  #Read and prepare files
  cat("\n\n## Structured data###\n")
  cat("#####################\n")
  
  preparedStructuredTablesFilePath <- file.path(outputPath, "preparedStructuredTables.RData")
  structuredTableNames <- c("labs", "meds", "demos", "dx")
  
  if (file.exists(preparedStructuredTablesFilePath)) {
    cat("\n## 0102 - Loading files...###\n")
    load(preparedStructuredTablesFilePath)
    structuredTableNames <- c(structuredTableNames)
    cat("# Done.")
  } else {
    
    ## Read in the tables  
    cat("\n## 01 - Reading tables...###\n")
    
    demos <- readRPT("Demographics") #Demographics data
    dx <- readRPT("Diagnosis") #Diagnostics data
    labs <- readRPT("LAB") #Lab-work data
    meds <- readRPT("Medications") #Medications data
    
    ## Prepare the tables
    cat("\n## 02 - Preparing tables...###\n")
    #performs fixes on inconsistencies from excel files
    #reduces redundency from Notes
    source(file.path(codePath,"EMR_Prep_Structured.R"))
     
    save(list = structuredTableNames, file = preparedStructuredTablesFilePath)
  }
  
  #De-identification
  cat("\n## De-identification of Structured data###\n")
  
  deIdStructuredTablesFilePath <- file.path(outputPath, "deIdStructuredTables.RData")
  
  if (file.exists(deIdStructuredTablesFilePath)) {
    cat("\n## 0304 - Loading files...###\n")
    load(preparedStructuredTablesFilePath)
    cat("# Done.")
  } else {
    
    #in labs and meds file, shifts dates in structured field
    cat("\n## 03 - Deidentification of Structured Fields...###\n")
    source(file.path(codePath,"EMR_Deid_Functions.R"))
    source(file.path(codePath,"EMR_Deid_Structured.R"))
    
    save(list = structuredTableNames, file = deIdStructuredTablesFilePath)
  }
  
  #Export files
  
  cat("## 05 - Exporting tables...###\n")
  writeCSV(demos, "Demographics")
  writeCSV(dx, "Diagnosis")
  writeCSV(labs, "LAB")
  writeCSV(meds, "Medications")
  
}




