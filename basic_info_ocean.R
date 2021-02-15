setwd("/Volumes/Disk2/Experiments/Huijie/Script")
library(raster)
library(Hmisc)
library(ggplot2)
library("RMySQL")

con<-dbConnect(MySQL(), user="root", password="mikania", 
               dbname="obis", host="127.0.0.1")

#MarineRealms
MarineRealms<-raster("../Raster/MarineRealms.tif")

rs<-dbSendQuery(con, "SELECT DISTINCT phylum FROM OBIS")

phylum<-fetch(rs, n=-1)


collist<-c("scientificNameID", "genus", "decimalLatitude", "decimalLongitude")
phyla<-phylum$phylum[2]
for (phyla in phylum$phylum){
  if (is.na(phyla)){
    next()
  }
  rs<-dbSendQuery(con, sprintf("SELECT DISTINCT genus FROM OBIS WHERE phylum='%s'", phyla))
  groups<-fetch(rs, n=-1)
  genus<-groups$genus[1]
  for (genus in groups$genus){
    if (is.na(genus)){
      next()
    }
    print(genus)
    
    df_file<-sprintf("../obis/%s/export_%s.csv", phyla, genus)
    if (file.exists(df_file)){
      
      df_occ<-read.table(df_file, head=F, sep=",", stringsAsFactors = F)
      colnames(df_occ)<-c("species", "genus", "decimalLatitude", "decimalLongitude")
      
      
      df_occ<-df_occ[which((!is.na(df_occ$decimalLatitude))&(!is.na(df_occ$decimalLongitude))),]
      
      if (nrow(df_occ)<=0){
        next()
      }
      df_occ$MarineRealms<-extract(MarineRealms, df_occ[, c("decimalLongitude", "decimalLatitude")])
      dir.create(sprintf("../occ_obis/%s", phyla), showWarnings = F)
      write.table(df_occ, sprintf("../occ_obis/%s/export_%s.csv", phyla, genus), row.names = F, sep=",")
    }
  }
}



