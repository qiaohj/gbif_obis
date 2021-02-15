setwd("/Volumes/Disk2/Experiments/Huijie/Script")
library(robis)
args = commandArgs(trailingOnly=TRUE)
nodeid=args[1]
if (file.exists(sprintf("obis/obis_%s.RData", nodeid))){
  asdfasd
}


#nodeid<-"6c17c09e-5cc2-4d5a-8463-e866731d35a1"
crete <- occurrence(nodeid = nodeid, verbose=F)
saveRDS(crete, sprintf("obis/obis_%s.RData", nodeid))
