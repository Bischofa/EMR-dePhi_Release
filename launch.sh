# The first argument has to be either STRUCTURED' 'UNSTRUCTURED' or an empty string (default).
R_DEPHI_MODE=$1 bash -c '[[ "STRUCTURED UNSTRUCTURED" =~ $R_DEPHI_MODE ]] && Rscript --vanilla launchDePhi.R | tee ${R_DEPHI_MODE}.log'
