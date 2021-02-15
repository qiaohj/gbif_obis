setwd("/Volumes/Disk2/Experiments/Huijie/Script")
library(raster)
library(Hmisc)
library(ggplot2)
library(RMySQL)

con<-dbConnect(MySQL(), user="root", password="mikania", 
               dbname="gbif", host="127.0.0.1")

args = commandArgs(trailingOnly=TRUE)
class<-"Mammalia"
class<-args[1]

rs<-dbSendQuery(con, sprintf("SELECT DISTINCT genus FROM %s", class))
df_genus<-fetch(rs, n=-1)

genus<-df_genus$genus[2]
new<-F
if (new){
  df_table_occ_road<-data.frame()
  df_table_occ_country_road<-data.frame()
  df_table_occ_pa<-data.frame()
  df_table_biome<-data.frame()
  df_log<-data.frame()
}
folder<-sprintf("stat/%s", class)
if (!dir.exists(folder)){
  dir.create(folder)
}
if (!new){
  df_table_occ_road<-read.table(sprintf("%s/df_table_occ_road.csv", folder), head=T, sep=",", stringsAsFactors = F)
  df_table_occ_country_road<-read.table(sprintf("%s/df_table_occ_country_road.csv", folder), head=T, sep=",", stringsAsFactors = F)
  df_table_occ_pa<-read.table(sprintf("%s/df_table_occ_pa.csv", folder), head=T, sep=",", stringsAsFactors = F)
  df_table_biome<-read.table(sprintf("%s/df_table_biome.csv", folder), head=T, sep=",", stringsAsFactors = F)
  df_log<-read.table(sprintf("%s/df_log.csv", folder), head=T, sep=",", stringsAsFactors = F)
}
for (genus in df_genus$genus){
  print(genus)
  if (genus %in% df_table_biome$genus){
    next()
  }
  target<-sprintf("../occ_gbif/%s/export_%s.csv", class, genus)
  if (!file.exists(target)){
    next()
  }
  df_occ<-read.table(target, head=T, sep=",", stringsAsFactors = F, quote = "\"")
  ncol_with_error<-nrow(df_occ)
  df_occ<-df_occ[(df_occ$decimalLatitude!=-90),]
  ncol_without_error<-nrow(df_occ)
  item<-data.frame(genus=genus, ncol_with_error=ncol_with_error, ncol_without_error=ncol_without_error)
  if (nrow(df_log)==0){
    df_log<-item
  }else{
    df_log<-rbind(df_log, item)
  }
  
  
  #What % of records per taxa fall within 1km of a road, what % in 2.5km and what % 5km
  road_cuts<-c(0, 1000, 2500, 5000)
  df_occ_road<-df_occ[which(!is.na(df_occ$road)),]
  if (nrow(df_occ_road)==0){
    next()
  }
  df_occ_road$road_cut2<-cut2(df_occ_road$road, road_cuts)
  table_occ_road<-data.frame(table(df_occ_road$road_cut2))
  table_occ_road$genus<-genus
  if (nrow(df_table_occ_road)==0){
    df_table_occ_road<-table_occ_road
  }else{
    df_table_occ_road<-rbind(df_table_occ_road, table_occ_road)
  }
  #What % of records per taxa fall within 2.5km per country
  threshold<-2500
  df_occ_country_road<-df_occ[which(!is.na(df_occ$countryCode)),]
  if (nrow(df_occ_country_road)==0){
    next()
  }
  df_occ_country_road$lower_th<-F
  if (nrow(df_occ_country_road[which(df_occ_country_road$road<=threshold),])>0){
    df_occ_country_road[which(df_occ_country_road$road<=threshold),]$lower_th<-T
  }
  
  table_occ_country<-data.frame(table(df_occ_country_road$countryCode, df_occ_country_road$lower_th))
  table_occ_country<-table_occ_country[which(table_occ_country$Var1!=""),]
  table_occ_country_road<-merge(table_occ_country[which(table_occ_country$Var2==TRUE),],
                             table_occ_country[which(table_occ_country$Var2==FALSE),],
                             by="Var1", all=T)
  table_occ_country_road<-table_occ_country_road[, c("Var1", "Freq.x", "Freq.y")]
  
  colnames(table_occ_country_road)<-c("countryCode", "in_th", "out_th")
  table_occ_country_road[is.na(table_occ_country_road)]<-0
  table_occ_country_road$all<-table_occ_country_road$in_th+table_occ_country_road$out_th
  table_occ_country_road<-table_occ_country_road[order(-table_occ_country_road$all),] 
  table_occ_country_road$genus<-genus
  if (nrow(df_table_occ_country_road)==0){
    df_table_occ_country_road<-table_occ_country_road
  }else{
    df_table_occ_country_road<-rbind(df_table_occ_country_road, table_occ_country_road)
  }
  
  
  #What % of records falls within 2.5km of a road inside a Protected area vs outside a protected area
  
  df_occ_pa<-df_occ_country_road[which(!is.na(df_occ_country_road$pa)),]
  if (nrow(df_occ_pa)==0){
    next()
  }
  
  table_occ_pa<-data.frame(table(df_occ_pa$pa, df_occ_pa$lower_th))
  colnames(table_occ_pa)<-c("is_pa", "in_th", "Freq")
  table_occ_pa$genus<-genus
  if (nrow(df_table_occ_pa)==0){
    df_table_occ_pa<-table_occ_pa
  }else{
    df_table_occ_pa<-rbind(df_table_occ_pa, table_occ_pa)
  }
  
  #	What % of records in each biome vs what % species (i.e. if 1000 records for 100 species, what percentage 
  #of records fall into each biome and what % of species to explore sample bias, 
  #could also look at % global roads in each biome relative to area of each biome)
  
  df_occ_biome<-df_occ[which(!is.na(df_occ$biome)),]
  if (nrow(df_occ_biome)==0){
    next()
  }
  
  table_occ_biome<-data.frame(table(df_occ_biome$biome))
  colnames(table_occ_biome)<-c("biome", "num_occ")
  df_species<-unique(df_occ_biome[, c("species", "biome")])
  
  table_species_biome<-data.frame(table(df_species$biome))
  colnames(table_species_biome)<-c("biome", "num_species")
  
  table_biome<-merge(table_occ_biome, table_species_biome, by="biome")
  
  table_biome$per_occ<-table_biome$num_occ/sum(table_biome$num_occ)
  table_biome$per_species<-table_biome$num_species/sum(table_biome$num_species)
  table_biome$genus<-genus
  if (nrow(df_table_biome)==0){
    df_table_biome<-table_biome
  }else{
    df_table_biome<-rbind(df_table_biome, table_biome)
  }
  
  write.table(df_table_occ_road, sprintf("%s/df_table_occ_road.csv", folder), row.names=F, sep=",")
  write.table(df_table_occ_country_road, sprintf("%s/df_table_occ_country_road.csv", folder), row.names=F, sep=",")
  write.table(df_table_occ_pa, sprintf("%s/df_table_occ_pa.csv", folder), row.names=F, sep=",")
  write.table(df_table_biome, sprintf("%s/df_table_biome.csv", folder), row.names=F, sep=",")
  write.table(df_log, sprintf("%s/df_log.csv", folder), row.names=F, sep=",")

}

