library(raster)
library(rgdal)
setwd("/media/huijieqiao/Speciation_Extin/GBIF_OBIS/Script")
countries<-rgdal::readOGR("../TM_WORLD_BORDERS-0.3", "TM_WORLD_BORDERS-0.3")

country_iso2<-unique(countries$ISO2)
#country_iso2<-as.character(country_iso2)
res<-"10km"
species<-"Amphibia"
df<-data.frame()
args = commandArgs(trailingOnly=TRUE)
res<-args[1]
species<-args[2]

#for (res in c("5km", "10km")){
mask<-raster(sprintf("../Raster/mask_%s.tif", res))
#for (species in c("Amphibia", "Aves", "Mammalia", "Reptilia")){
r_occ<-raster(sprintf("%s/%s_number_occ_per_cell.tif", res, species))
#r_sp<-raster(sprintf("%s/%s_number_species_per_cell.tif", res, species))
iso2<-'CN'
for (iso2 in country_iso2){
  print(paste(res, species, iso2, sep="/"))
  shapes<-countries[countries$ISO2==iso2,]
  #plot(shapes)
  r_occ_crop<-raster::mask(mask, shapes)
  v<-values(r_occ_crop)
  all_pixels<-length(v[which(!is.na(v))])
  
  r_occ_crop<-raster::mask(r_occ, shapes)
  #plot(r_occ_crop)
  v<-values(r_occ_crop)
  sampled_pixels<-length(v[which(!is.na(v))])
  item<-data.frame(res=res, group=species, iso2=iso2, all_pixels=all_pixels, sampled_pixels=sampled_pixels)
  if (nrow(df)==0){
    df<-item
  }else{
    df<-rbind(df, item)
  }
}
#}
#}
write.table(df, sprintf("sample_coverage/sampled_pixels_%s_%s.csv", res, species), row.names=F, sep=",")
