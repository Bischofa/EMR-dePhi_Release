
#EMR_Deid.R Info ----
# Script to launch the de identification of the free-text present in the folder Files_Stored
# The script operates per subfolder. This piece of code is not intended to be shared over the network.
# The scrip is meant to be launched on the top level.
#Wendy Tang & Antoine Lizee @ UCSF 09/14
#tangwendy92@gmail.com

# Deidentify Structured Fields ----

# Shift date for all columns of all tables with dates. 
for (dfName in structuredTableNames) {
  cat("Treating table", dfName, "\n")
  dfi <- get(dfName)
  dateColumns <- grep("date", colnames(dfi), ignore.case = T)
  dfi[dateColumns] <- lapply(dfi[dateColumns], shift_field_dates)
  assign(dfName, dfi)
}