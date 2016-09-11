
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

#Ensure encoding is UTF8 if run on Windows
if(.Platform$OS.type == "windows"){
  notes$NOTE_TEXT <- sapply(1:dim(notes)[1],function(x){iconv(notes[x,11],from="",to="UTF-8")})
}

#Fix notes
notes$CONTACT_DATE_REAL <- as.Date(notes$CONTACT_DATE_REAL, origin = "1840-12-31")

colnames(notes)[grepl("note.text", colnames(notes), ignore.case = TRUE)] <- "NOTE_TEXT" 

tableNames <- unstructuredTableNames
source("Code/EMR_Prep.R")


# reducing Notes ----------------------------------------------------------

cat("## Reducing notes...\n")

uniqueNotesIds <- unique(notes$NOTE_ID)
nNotesIds <- length(uniqueNotesIds)
chunkSize <- 10000
nChunk <- ceiling(nNotesIds/chunkSize)

#Initialization
chunk = 1
cat("\t#Treating chunk", chunk, "/", nChunk ,"...\n")

chunkNotesIds <- uniqueNotesIds[(chunkSize*(chunk-1)+1) : (chunkSize*chunk)]
notesChunk <- notes[notes$NOTE_ID %in% chunkNotesIds,]

notes_reduced <- ddply(notesChunk, ~ NOTE_ID, function(notes_i) { # Midly tested with notes_i <- notes[ notes$NOTE_ID == 7354509, ]
  lastNoteLines <- notes_i[ notes_i$NOTE_CSN_ID == max(notes_i$NOTE_CSN_ID), ]
  result <- lastNoteLines[nrow(lastNoteLines),]
  result$NOTE_TEXT <- paste(lastNoteLines[order(lastNoteLines$LINE), "NOTE_TEXT"], collapse = " ")
  result$`Note Text` <- NULL
  return(result)
}, .progress = "text")
cat("\t#Binding...\n")
notes_reduced.final <- notes_reduced


#Iterations
if (nChunk > 1) {
  for (chunk in 2:nChunk) {
    cat("\t#Treating chunk", chunk, "/", nChunk ,"...\n")
    
    if (chunk == nChunk) {
      chunkNotesIds <- uniqueNotesIds[(chunkSize*(chunk-1)+1) : nNotesIds]
    } else { chunkNotesIds <- uniqueNotesIds[(chunkSize*(chunk-1)+1) : (chunkSize*chunk)] }
    
    notesChunk <- notes[notes$NOTE_ID %in% chunkNotesIds,]
    
    notes_reduced <- ddply(notesChunk, ~ NOTE_ID, function(notes_i) { # Midly tested with notes_i <- notes[ notes$NOTE_ID == 7354509, ]
      lastNoteLines <- notes_i[ notes_i$NOTE_CSN_ID == max(notes_i$NOTE_CSN_ID), ]
      result <- lastNoteLines[nrow(lastNoteLines),]
      result$NOTE_TEXT <- paste(lastNoteLines[order(lastNoteLines$LINE), "NOTE_TEXT"], collapse = " ")
      result$`Note Text` <- NULL
      return(result)
    }, .progress = "text")
    cat("\t#Binding...\n")
    notes_reduced.final <- rbind(notes_reduced.final, notes_reduced)
  }
}
cat("## Done.\n")

notes <- notes_reduced.final


