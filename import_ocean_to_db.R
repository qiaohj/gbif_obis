setwd("/Volumes/Disk2/Experiments/Huijie/Script")

library("RMySQL")
con <- dbConnect(MySQL(),
                 user="root", password="mikania", port=3306,
                 dbname="gbif", host="127.0.0.1")

rdata<-list.files("/Volumes/Disk2/Experiments/Huijie/Script/obis", include.dirs=F, full.name=T)
r<-rdata[1]

r<-"/Volumes/Disk2/Experiments/Huijie/Script/obis/obis_4bf79a01-65a9-4db6-b37b-18434f26ddfc.RData"
for (r in rdata[31]){
  print(r)
  if (grepl("RData", r)){
    df<-readRDS(r)
    if (nrow(df)>0){
      dbWriteTable(con, value = df, name = sprintf("OBIS_%s", gsub("-", "_", "4bf79a01-65a9-4db6-b37b-18434f26ddfc")), append = TRUE, row.names=F) 
    }
  }
}
