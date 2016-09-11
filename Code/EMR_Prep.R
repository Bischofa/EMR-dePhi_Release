
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


for (dfName in tableNames) {
  cat("Transforming date for table", dfName, "\n")
  dfi <- get(dfName)
  dateColumns <- grep("date", colnames(dfi), ignore.case = T)
  dfi[dateColumns] <- lapply(dfi[dateColumns], function(vec) {
    if("character" %in% class(vec)){
      as.Date(vec, "%Y-%m-%d")
    } else if("POSIXct" %in% class(vec)){
      as.Date(vec)
    } else {
      vec
      }
    })
  assign(dfName, dfi)
}


#MRN check
changeColumnName <- function(df, oldName, newName = "PAT_MRN_ID") {
  colnames(df)[grep(oldName, colnames(df), ignore.case = T)] <- newName
  return(df)
}

for (dfName in tableNames) {
  cat("Transforming MRN ids for table", dfName, "\n")
  # Change column name
  dfi <- changeColumnName(get(dfName), "MRN")
  stopifnot(sum("PAT_MRN_ID" %in% names(dfi)) == 1)
  # Make sure each MRN has 8 digits
  dfi$PAT_MRN_ID <- ifelse(nchar(dfi$PAT_MRN_ID) < 8, formatC(dfi$PAT_MRN_ID,width=8,format="d",flag=0), dfi$PAT_MRN_ID)
  assign(dfName, dfi)
}


