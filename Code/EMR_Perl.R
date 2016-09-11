
#EMR_Perl.R Info ----
# Script to launch the de-identification of the files present in the folder EMR_Input 
# Script meant to connect with Perl from R 
# The script operates per subfolder. This piece of code is not intended to be shared over the network.
# The script is meant to be launched on the top level.
#
# Authors: Wendy Tang & Antoine Lizee @ UCSF 09/14
# Contact: tangwendy92@gmail.com
#
# Open Source Perl Deid Software Courtesy of:
# Automated De-Identification of Free-Text Medical Records (Paper)
# Authors: Neamatullah I, Douglass M, Lehman LH, Reisner A, Villarroel M, Long WJ, Szolovits P, Moody GB, Mark RG, Clifford GD. 

library(parallel)

batch_size <- 1000
job_batch <- 10 # Approximate number of jobs that prints a '#' on the screen.
n_cores <- 10

# Preparation of the notes ------------------------------------------------
cat("#Preparation of the notes\n")

deid_NoteType = c("Progress Notes", "Ambulatory Progress Notes", "H&P", "Letter")
notes <- notes[notes$note_type %in% deid_NoteType,]

#Prepare files for software ----
#Deid Perl Software requires a specific format, so we make
#the existing note format compatible with software requirements- see documentation
if (perl_test_run) {
  notes_perl <- notes[1:987,]
} else {
  notes_perl <- notes
}

notes_perl$CONTACT_DATE <- format(notes_perl$CONTACT_DATE,"%m/%d/%Y") #date appears this way

notes_perl$NOTE_TEXT <- gsub("\n"," ",notes_perl$NOTE_TEXT) #these cause errors in the formatting of the text
notes_perl$NOTE_TEXT <- gsub("\t"," ",notes_perl$NOTE_TEXT)
notes_perl$NOTE_TEXT <- gsub("\r"," ",notes_perl$NOTE_TEXT)

notes_text <- paste(
  "START_OF_RECORD=<", notes_perl$PAT_MRN_ID ,">||||<", notes_perl$NOTE_ID,">||||<",notes_perl$CONTACT_DATE,">||||\n",
  notes_perl$NOTE_TEXT,
  "\n||||END_OF_RECORD")


# Exportation of the note files -------------------------------------------
cat("#Exportation of the note files\n")

n_batches <- nrow(notes_perl) %/% batch_size

files_folder <- file.path("files", project)
files_path <- file.path(perl_env, files_folder)
dir.create(files_path, showWarnings = FALSE, recursive = TRUE)

if( length(existing_text <- list.files(files_path, pattern=".text")) > 0 ){
  warning("Removing existing .text files")
  unlink(file.path(files_path, "*"))
}

for (i in 1:n_batches - 1) {
  # We need native.enc in order to avoid any error when writing strings with random bytes in them.
  fileConn <- file(file.path(files_path, paste("notes", i, "text", sep = ".")), encoding = "native.enc")
  writeLines(notes_text[i*batch_size + 1:batch_size], fileConn)
  close(fileConn)
}
#Write the last one
i <- i+1
fileConn <- file(file.path(files_path, paste("notes", i, "text", sep = ".")), encoding = "native.enc")
writeLines(notes_text[ (i*batch_size+1) : (length(notes_text)) ], fileConn)
close(fileConn)


# Running the software ----------------------------------------------------
cat("#Running the deid software\n")
cwd <- setwd(perl_env)
cl <- makeCluster(n_cores, rscript_args = "--vanilla")
clusterExport(cl, c("files_folder", "job_batch"))
t0 <- Sys.time()

getSilent <- parSapplyLB(cl, 0:n_batches, function(i) {
  if (i %% job_batch == 0) {
    system("echo -n '#'")
  }
  cmd <- sprintf("perl deid.pl %s/notes.%i deid.config", files_folder, i)
  system(cmd, intern = TRUE)
})

cat("\n### Done in", format(Sys.time() - t0), "\n")
stopCluster(cl)

setwd(cwd)


# Reading in and treating the output -----------------------------------------
cat("#Reading in and treating the output\n")

deid_notes <- readLines(file.path(files_path, "notes.0.res"), encoding = "UTF-8")
for (i in 1:n_batches) {
  deid_notes <- c(deid_notes, readLines(file.path(files_path, sprintf("notes.%i.res", i)), encoding = "UTF-8"))
}
#read lines in according to software format
#then, ensure the same number of lines
stopifnot(length(deid_notes) == (nrow(notes_perl)*3) )
deid_notes <- deid_notes[seq(from=2,to= (length(deid_notes) -1 ) ,by=3)]
stopifnot(length(deid_notes) == nrow(notes_perl))
notes$NOTE_TEXT <- deid_notes

