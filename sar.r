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
#ress<-c(0.1, 1)
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
  coverage<-readRDS(file=sprintf("../Data/Coverage/%s.rda", class))
  
  res=0.1
  n_species<-length(unique(df$species))
  for (res in ress){
    coverage_item<-coverage[which(coverage$res==res),]
    coverage_item_ocean<-coverage_item[which(coverage_item$type=="Ocean"),]
    coverage_item_land<-coverage_item[which(coverage_item$type=="Terrestrial"),]
    t_folder<-sprintf("../Raster/ocean/%.2f", res)
    mask_ocean<-mask_list_ocean[[sprintf("res_%.2f", res)]]
    coverage_ocean_map<-raster(sprintf("%s/%s_number_species_per_cell.tif", t_folder, class))
    coverage_ocean_map_p<-data.table(rasterToPoints(coverage_ocean_map))
    colnames(coverage_ocean_map_p)[3]<-"N_SP"
    coverage_ocean_map_p<-coverage_ocean_map_p[order(-N_SP)]
    coverage_ocean_map_p$cuts<-as.numeric(cut2(as.numeric(row.names(coverage_ocean_map_p)),
                                    seq(1, nrow(coverage_ocean_map_p), by=nrow(coverage_ocean_map_p)/100)))
    coverage_ocean_map_p$ocean_v<-raster::extract(mask_ocean, coverage_ocean_map_p[, c("x", "y")])
    df$ocean_v<-extract(mask_ocean, as.matrix(df[, c("decimalLongitude", "decimalLatitude")]))
    n_sp_ocean<-df[!is.na(ocean_v)]
    n_sp_ocean<-length(unique(n_sp_ocean$species))
    i=1
    for (i in c(1:100)){
      print(paste(class, res, "ocean", i))
      item_index<-coverage_ocean_map_p[cuts<=i]$ocean_v
      df_item<-df[ocean_v %in% item_index]
      N_SP<-length(unique(unique(df_item$species)))
      item<-data.table(group=class, res=res, threshold=i, N_SP=N_SP, type="Ocean",
                       all_N_target_SP=n_sp_ocean, all_n_species=coverage_item_ocean$n_species,
                       n_coveraged=coverage_item_ocean$n_coveraged, n_all_p=coverage_item_ocean$n_all_p)
      if (is.null(result)){
        result<-item
      }else{
        result<-rbind(result, item)
      }
    }
    t_folder<-sprintf("../Raster/land/%.2f", res)
    mask_land<-mask_list_land[[sprintf("res_%.2f", res)]]
    
    coverage_land_map<-raster(sprintf("%s/%s_number_species_per_cell.tif", t_folder, class))
    coverage_land_map_p<-data.table(rasterToPoints(coverage_land_map))
    colnames(coverage_land_map_p)[3]<-"N_SP"
    coverage_land_map_p<-coverage_land_map_p[order(-N_SP)]
    coverage_land_map_p$cuts<-as.numeric(cut2(as.numeric(row.names(coverage_land_map_p)),
                                               seq(1, nrow(coverage_land_map_p), by=nrow(coverage_land_map_p)/100)))
    coverage_land_map_p$land_v<-raster::extract(mask_land, coverage_land_map_p[, c("x", "y")])
    df$land_v<-extract(mask_land, as.matrix(df[, c("decimalLongitude", "decimalLatitude")]))
    n_sp_land<-df[!is.na(land_v)]
    n_sp_land<-length(unique(n_sp_land$species))
    i=1
    for (i in c(1:100)){
      print(paste(class, res, "land", i))
      item_index<-coverage_land_map_p[cuts<=i]$land_v
      df_item<-df[land_v %in% item_index]
      N_SP<-length(unique(unique(df_item$species)))
      item<-data.table(group=class, res=res, threshold=i, N_SP=N_SP, type="Terrestrial",
                       all_N_target_SP=n_sp_land, all_n_species=coverage_item_land$n_species,
                       n_coveraged=coverage_item_land$n_coveraged, n_all_p=coverage_item_land$n_all_p)
      if (is.null(result)){
        result<-item
      }else{
        result<-rbind(result, item)
      }
    }
  }
}
saveRDS(result, file=sprintf("../Data/Coverage/SAR_%s.rda", class))
