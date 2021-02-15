library(raster)
library(Hmisc)
library(ggplot2)
library(RMySQL)
rm(list=ls())
if (F){
  mask<-raster("/Volumes/Disk2/Experiments/Huijie/Raster/MarineRealms.tif")
  masknew<-projectRaster(mask, res=c(0.045, 0.045), crs=crs(mask), method="ngb")
  v<-values(masknew)[!is.na(values(masknew))]
  values(masknew)[!is.na(values(masknew))]<-c(1:length(v))
  writeRaster(masknew, "/Volumes/Disk2/Experiments/Huijie/Raster/MarineRealms_5km.tif", overwrite=T)
}

con<-dbConnect(MySQL(), user="root", password="mikania", 
               dbname="gbif", host="127.0.0.1")

rs<-dbSendQuery(con, "SELECT DISTINCT phylum FROM OBIS")

phylum<-fetch(rs, n=-1)


collist<-c("scientificNameID", "genus", "decimalLatitude", "decimalLongitude")
phyla<-phylum$phylum[2]

mask<-raster("/Volumes/Disk2/Experiments/Huijie/Raster/mask_ocean_10km.tif")
p_mask<-data.frame(rasterToPoints(mask))
colnames(p_mask)[3]<-"v"

for (phyla in phylum$phylum){
  mask<-raster("/Volumes/Disk2/Experiments/Huijie/Raster/mask_ocean_10km.tif")
  
  print(phyla)
  if (is.na(phyla)){
    next()
  }
  if (file.exists(sprintf("10km/obis/%s_number_occ_per_cell.tif", phyla))){
    next()
  }
  rs<-dbSendQuery(con, sprintf("SELECT * FROM OBIS WHERE phylum='%s'", phyla))
  df<-fetch(rs, n=-1)
  
  df$decimalLatitude<-as.numeric(df$decimalLatitude)
  df$decimalLongitude<-as.numeric(df$decimalLongitude)
  df$v<-extract(mask, df[, c("decimalLongitude", "decimalLatitude")])
  
  df<-df[which(!is.na(df$v)),]
  dim(df)
  
  #head(df)
  #head(p_mask)
  
  df_gbif<-df[, c("scientificNameID", "v")]
  occ_count<-data.frame(table(df_gbif$v))
  colnames(occ_count)<-c("v", "occ_count")
  
  df_species<-unique(df_gbif)
  species_count<-data.frame(table(df_species$v))
  colnames(species_count)<-c("v", "species_count")
  
  df_v<-merge(p_mask, occ_count, by="v", all=T)
  df_v<-merge(df_v, species_count, by="v", all=T)
  
  df_v[which(is.na(df_v$occ_count)),]$occ_count<-0
  df_v[which(is.na(df_v$species_count)),]$species_count<-0
  
  #head(df_v)
  #write.table(df_v, sprintf("%s_number_occ_species_per_cell.csv", class), row.names = F, sep=",")
  
  mask<-raster("/Volumes/Disk2/Experiments/Huijie/Raster/mask_ocean_10km.tif")
  values(mask)[!is.na(values(mask))]<-df_v$occ_count
  writeRaster(mask, sprintf("10km/obis/%s_number_occ_per_cell.tif", phyla), overwrite=T)
  
  mask<-raster("/Volumes/Disk2/Experiments/Huijie/Raster/mask_ocean_10km.tif")
  values(mask)[!is.na(values(mask))]<-df_v$species_count
  writeRaster(mask, sprintf("10km/obis/%s_number_species_per_cell.tif", phyla), overwrite=T)
  
}
