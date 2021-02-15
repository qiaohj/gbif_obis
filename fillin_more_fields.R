setwd("/Volumes/Disk2/Experiments/Huijie/Script")
library(raster)
library(Hmisc)
library(ggplot2)
library(RMySQL)
con<-dbConnect(MySQL(), user="root", password="mikania", 
               dbname="gbif", host="127.0.0.1")
#Use GLM to explore relationship with roads, rivers, coast and light intensity

#min road distance
road<-raster("../Raster/minrodist_p1.tif")
#road_cuts<-seq(from=0, to=max(values(road), na.rm = T), by=1000)
#hist(values(road))

#biome
biome<-raster("../Raster/biome_number1b_lonlat.tif")
#protected area
pa<-raster("../Raster/pa2_lonlat.tif")
#river
river<-raster("../Raster/river_dist11_lonlat.tif")
#coast<
coast<-raster("../Raster/coast_km11_lonlat.tif")

nitliggrey<-raster("../Raster/nightlight_lonlat.tif")

bio1<-raster("../Raster/bio1_lonlat.tif")
bio12<-raster("../Raster/bio12_lonlat.tif")

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
    
    df_file<-sprintf("../gbif/%s/export_%s.csv", class, genus)
    targetFolder<-sprintf("../occ_gbif/%s", class)
    if (!dir.exists(targetFolder)){
      dir.create(targetFolder)
    }
    target<-sprintf("%s/export_%s.csv", targetFolder, genus)
    if (file.exists(target)){
      next()
    }
    if (file.exists(df_file)){
      
      df_occ<-read.table(df_file, head=F, sep=",", stringsAsFactors = F, quote = "\"")
      if (!is.na(df_occ[1,1])){
        if (df_occ[1,1]=='species'){
          df_occ<-df_occ[-1,]
        }
      }
      #print(colnames(df_occ))
      colnames(df_occ)<-c("species", "genus", "decimalLatitude", "decimalLongitude", "month", "year", "countryCode", 
                          "institutionCode", "coordinateUncertaintyInMeters", "coordinatePrecision", "basisOfRecord")
      df_occ<-df_occ[, c("species", "genus", "decimalLatitude", "decimalLongitude", "month", "year", "countryCode", 
                         "coordinateUncertaintyInMeters", "coordinatePrecision", "basisOfRecord")]
      df_occ$decimalLatitude<-as.numeric(df_occ$decimalLatitude)
      df_occ$decimalLongitude<-as.numeric(df_occ$decimalLongitude)
      df_occ<-df_occ[which((!is.na(df_occ$decimalLatitude))&(!is.na(df_occ$decimalLongitude))),]
      
      if (nrow(df_occ)<=0){
        next()
      }
      df_occ$road<-extract(road, df_occ[, c("decimalLongitude", "decimalLatitude")])
      df_occ$biome<-extract(biome, df_occ[, c("decimalLongitude", "decimalLatitude")])
      df_occ$pa<-extract(pa, df_occ[, c("decimalLongitude", "decimalLatitude")])
      
      if (nrow(df_occ[which(is.na(df_occ$pa)),])>0){
        df_occ[which(is.na(df_occ$pa)),]$pa<-0
      }
      df_occ$river<-extract(river, df_occ[, c("decimalLongitude", "decimalLatitude")])
      df_occ$coast<-extract(coast, df_occ[, c("decimalLongitude", "decimalLatitude")])
      df_occ$nitliggrey<-extract(nitliggrey, df_occ[, c("decimalLongitude", "decimalLatitude")])
      df_occ$bio1<-extract(bio1, df_occ[, c("decimalLongitude", "decimalLatitude")])
      df_occ$bio12<-extract(bio12, df_occ[, c("decimalLongitude", "decimalLatitude")])
      
      write.table(df_occ, target, row.names = F, sep=",")
    }
  }
#}
if (F){
  con <- file(df_file, "rb")
  rawContent <- readLines(con) # empty
  close(con)  # close the connection to the file, to keep things tidy
  expectedColumns <- 10
  delim <- ","
  
  indxToOffenders <-
    sapply(rawContent, function(x)   # for each line in rawContent
      length(gregexpr(delim, x)[[1]]) != expectedColumns   # count the number of delims and compare that number to expectedColumns
    ) 
  head(indxToOffenders[which(!indxToOffenders)])
}
