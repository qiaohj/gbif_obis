setwd("/Volumes/Disk2/Experiments/Huijie/Script")
library(raster)
library(Hmisc)
library(ggplot2)
library(RMySQL)
con<-dbConnect(MySQL(), user="root", password="mikania", 
               dbname="gbif", host="127.0.0.1")
#Use GLM to explore relationship with roads, rivers, coast and light intensity

#min city distance
city<-raster("../Raster/city_lonlat.tif")
classes<-c("Amphibia", "Aves", "Mammalia", "Reptilia")
args = commandArgs(trailingOnly=TRUE)
class<-args[1]
#for (class in classes){
  rs<-dbSendQuery(con, sprintf("SELECT DISTINCT genus FROM %s", class))
  df_genus<-fetch(rs, n=-1)
  #df_genus<-read.table("/Volumes/DATA/Dropbox/Dropbox/Papers/Alice_Bird/genus.csv", head=T, sep=",")
  df_genus$count_csv<-0
  genus<-df_genus$genus[10]
  genus<-"Pitta"
  for (genus in df_genus$genus){
    print(paste(class, genus))
    
    targetFolder<-sprintf("../occ_gbif/%s", class)
    target<-sprintf("%s/export_%s.csv", targetFolder, genus)
    if (!file.exists(target)){
      next()
    }
    if (file.exists(target)){
      
      df_occ<-read.table(target, head=T, sep=",", stringsAsFactors = F, quote = "\"")
      
      
      
      df_occ$city_distance<-extract(city, df_occ[, c("decimalLongitude", "decimalLatitude")])
      
      write.table(df_occ, target, row.names = F, sep=",")
    }
  }
#}
