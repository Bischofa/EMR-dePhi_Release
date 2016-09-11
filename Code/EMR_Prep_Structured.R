#EMR_Prep.R Info ----
# Script to simplify excel files by unique MRN and visit date and strip identifiers.
# The script operates per subfolder. This piece of code is not intended to be shared over the network.
# The scrip is meant to be launched on the top level.
#Wendy Tang & Antoine Lizee @ UCSF 09/14
#tangwendy92@gmail.com

#Function: Deidentify Notes,Meds,and Labs file; Simplifies the formatting of the Notes file 

#File Fixes ---
#We see some variation when files are pulled from server and fix them here.
#Change character formats are as they should be.



#Fix demos
cat("## Fixing the demos...\n")
demos$`Date of Birth` <- as.Date(demos$`Date of Birth`, format="%m-%d-%Y")
stopifnot(class(demos$`Date of Birth`) %in% c("Date","POSIXct","POSIXt"))


tableNames <- structuredTableNames

source("Code/EMR_Prep.R")

