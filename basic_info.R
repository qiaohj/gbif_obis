setwd("/Volumes/Disk2/Experiments/Huijie/Script")
library(raster)
library(Hmisc)
library(ggplot2)

#Use GLM to explore relationship with roads, rivers, coast and light intensity

#min road distance
road<-raster("../Raster/minrodist_p1.tif")
road_cuts<-seq(from=0, to=max(values(road), na.rm = T), by=1000)
hist(values(road))

#biome
biome<-raster("../Raster/biome_number1b_lonlat.tif")
#protected area
pa<-raster("../Raster/pa_lonlat.tif")
#river
river<-raster("../Raster/river_dist11_lonlat.tif")
#coast<
coast<-raster("../Raster/coast_km11_lonlat.tif")

df_genus<-read.table("/Volumes/DATA/Dropbox/Dropbox/Papers/Alice_Bird/genus.csv", head=T, sep=",", stringsAsFactors = F)
df_genus$count_csv<-0
genus<-df_genus$genus[2]
for (genus in df_genus$genus){
  print(genus)
  
  df_file<-sprintf("../gbif/export_%s.csv", genus)
  if (file.exists(df_file)){
    df_file<-sprintf("../gbif/export_%s.csv", genus)
    df_occ<-read.table(df_file, head=F, sep=",", stringsAsFactors = F)
    if (!is.na(df_occ[1,1])){
      if (df_occ[1,1]=='species'){
        df_occ<-df_occ[-1,]
      }
    }
    
    colnames(df_occ)<-c("species", "genus", "decimalLatitude", "decimalLongitude", "month", "year", "countryCode", 
                        "institutionCode", "coordinateUncertaintyInMeters", "coordinatePrecision")
    
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
    write.table(df_occ, sprintf("../occ/export_%s.csv", genus), row.names = F, sep=",")
  }
}


genus<-"Caprimulgus"

