#EMR_Deid_Functions.R Info ----
# Functions for the de identification of the free-text present in the folder Files_Stored
# The script operates per subfolder. This piece of code is not intended to be shared over the network.
# The scrip is meant to be launched on the top level.
#
#Copyright Wendy Tang & Antoine Lizee @ UCSF 09/14
#tangwendy92@gmail.com

#Functions for structured fields ----

shift_field_dates <- function(dates_col = notes$CONTACT_DATE,
                        date_shift_constant = T){
#  stopifnot(is.integer(offset_days))
  if(date_shift_constant == T){
    return(dates_col + offset_days)
  } else{
    #will implement functionality if needed
  }  
}




