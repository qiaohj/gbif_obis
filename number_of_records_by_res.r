library(raster)
library(Hmisc)
library(ggplot2)
library(RMySQL)
library(data.table)
rm(list=ls())
setwd("/media/huijieqiao/Speciation_Extin/GBIF_OBIS/Script")
ress<-seq(0, 1, by=0.05)
ress[1]<-0.01
ress[2]<-0.045
res<-1
mask_list_land<-list()
mask_p_list_land<-list()
mask_list_ocean<-list()
mask_p_list_ocean<-list()

for (res in ress){
  print(res)
  mask<-raster(sprintf("../Raster/mask_continent_%.2f.tif", res))
  mask_list_land[[sprintf("res_%.2f", res)]]<-mask
  p_mask<-data.table(rasterToPoints(mask))
  colnames(p_mask)[3]<-"land_v"
  mask_p_list_land[[sprintf("res_%.2f", res)]]<-p_mask
  
  mask<-raster(sprintf("../Raster/mask_ocean_%.2f.tif", res))
  mask_list_ocean[[sprintf("res_%.2f", res)]]<-mask
  p_mask<-data.table(rasterToPoints(mask))
  colnames(p_mask)[3]<-"ocean_v"
  mask_p_list_ocean[[sprintf("res_%.2f", res)]]<-p_mask
  
}

args = commandArgs(trailingOnly=TRUE)
class<-args[1]
#classes<-c("Actinopterygii", "Amphibia", "Annelida", "Arachnida", "Aves", "Cnidaria",
#           "Elasmobranchii", "Gastropoda", "Malacostraca", "Mammalia", "Reptilia")
#class<-"Cnidaria"


result<-NULL
for (class in c(class)){
  #con<-dbConnect(MySQL(), user="root", password="mikania", 
  #               dbname="gbif", host="172.16.120.79")
  #sql<-sprintf("SELECT * FROM %s", class)
  #rs<-dbSendQuery(con, sql)
  #df<-fetch(rs, n=-1)
  print(paste("reading", class))
  df1<-readRDS(sprintf("../Data/occ_without_NA_coordinate/GBIF/%s.RData", class))
  df2<-readRDS(sprintf("../Data/occ_without_NA_coordinate/OBIS/%s.RData", class))
  df2<-df2[, -9]
  #head(df)
  #df$decimalLatitude<-as.numeric(df$decimalLatitude)
  #df$decimalLongitude<-as.numeric(df$decimalLongitude)
  df<-rbindlist(list(df1, df2))
  n_occ<-nrow(df)
  n_species<-length(unique(df$species))
  res=0.1
  for (res in ress){
    print(paste(class, res))
    mask_label<-sprintf("res_%.2f", res)
    mask_land<-mask_list_land[[mask_label]]
    mask_land_p<-mask_p_list_land[[mask_label]]
    df$land_v<-extract(mask_land, as.matrix(df[, c("decimalLongitude", "decimalLatitude")]))
    
    df_land<-df[!is.na(land_v),]
    n_occ_with_xy_land<-nrow(df_land)
    #head(df)
    #head(p_mask)
    df_land<-df_land[, c("species", "land_v")]
    occ_count_land<-df_land[, .(occ_count = .N), by = land_v]
    df_species_land<-unique(df_land)
    species_count_land<-df_species_land[, .(species_count = .N), by = land_v]
    
    df_v_land<-merge(mask_land_p, occ_count_land, by="land_v", all=T)
    df_v_land<-merge(df_v_land, species_count_land, by="land_v", all=T)
    n_coveraged_land<-nrow(occ_count_land)
    n_all_p_land<-nrow(mask_land_p)
    t_folder<-sprintf("../Raster/land/%.2f", res)
    dir.create(t_folder, showWarnings = F, recursive = T)
    #head(df_v)
    #write.table(df_v, sprintf("%s_number_occ_species_per_cell.csv", class), row.names = F, sep=",")
    r<-mask_land
    no_na<-!is.na(values(r))
    values(r)[no_na]<-df_v_land$occ_count
    writeRaster(r, sprintf("%s/%s_number_occ_per_cell.tif", t_folder, class), overwrite=T)
    
    r<-mask_land
    no_na<-!is.na(values(r))
    values(r)[!is.na(values(r))]<-df_v_land$species_count
    writeRaster(r, sprintf("%s/%s_number_species_per_cell.tif", t_folder, class), overwrite=T)
    
    mask_ocean<-mask_list_ocean[[mask_label]]
    mask_ocean_p<-mask_p_list_ocean[[mask_label]]
    df$ocean_v<-extract(mask_ocean, as.matrix(df[, c("decimalLongitude", "decimalLatitude")]))
    
    df_ocean<-df[!is.na(ocean_v),]
    n_occ_with_xy_ocean<-nrow(df_ocean)
    #head(df)
    #head(p_mask)
    df_ocean<-df_ocean[, c("species", "ocean_v")]
    occ_count_ocean<-df_ocean[, .(occ_count = .N), by = ocean_v]
    df_species_ocean<-unique(df_ocean)
    species_count_ocean<-df_species_ocean[, .(species_count = .N), by = ocean_v]
    
    df_v_ocean<-merge(mask_ocean_p, occ_count_ocean, by="ocean_v", all=T)
    df_v_ocean<-merge(df_v_ocean, species_count_ocean, by="ocean_v", all=T)
    n_coveraged_ocean<-nrow(occ_count_ocean)
    n_all_p_ocean<-nrow(mask_ocean_p)
    t_folder<-sprintf("../Raster/ocean/%.2f", res)
    dir.create(t_folder, showWarnings = F, recursive = T)
    #head(df_v)
    #write.table(df_v, sprintf("%s_number_occ_species_per_cell.csv", class), row.names = F, sep=",")
    r<-mask_ocean
    no_na<-!is.na(values(r))
    values(r)[no_na]<-df_v_ocean$occ_count
    writeRaster(r, sprintf("%s/%s_number_occ_per_cell.tif", t_folder, class), overwrite=T)
    
    r<-mask_ocean
    no_na<-!is.na(values(r))
    values(r)[!is.na(values(r))]<-df_v_ocean$species_count
    writeRaster(r, sprintf("%s/%s_number_species_per_cell.tif", t_folder, class), overwrite=T)
    
    result_item<-data.frame(n_occ=n_occ, n_species=n_species, res=res, group=class, 
                            n_occ_with_xy=c(n_occ_with_xy_land, n_occ_with_xy_ocean),
                            n_coveraged=c(n_coveraged_land, n_coveraged_ocean),
                            n_all_p=c(n_all_p_land, n_all_p_ocean),
                            coverage_proportion=c(n_coveraged_land/n_all_p_land, n_coveraged_ocean/n_all_p_ocean),
                            type=c("Terrestrial", "Ocean"))
    if (is.null(result)){
      result<-result_item
    }else{
      result<-rbind(result, result_item)
    }
  }
}
saveRDS(result, file=sprintf("../Data/Coverage/%s.rda", class))
