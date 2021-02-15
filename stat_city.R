setwd("/Volumes/Disk2/Experiments/Huijie/Script")
library(raster)
library(Hmisc)
library(ggplot2)
library(RMySQL)

con<-dbConnect(MySQL(), user="root", password="mikania", 
               dbname="gbif", host="127.0.0.1")

args = commandArgs(trailingOnly=TRUE)
class<-"Amphibia"
class<-args[1]

rs<-dbSendQuery(con, sprintf("SELECT DISTINCT genus FROM %s", class))
df_genus<-fetch(rs, n=-1)

genus<-df_genus$genus[2]
new<-T
if (new){
  df_table_occ_city<-data.frame()
  df_table_occ_country_city<-data.frame()
}
folder<-sprintf("stat/%s", class)
if (!dir.exists(folder)){
  dir.create(folder)
}
if (!new){
  df_table_occ_city<-read.table(sprintf("%s/df_table_occ_city.csv", folder), head=T, sep=",", stringsAsFactors = F)
  df_table_occ_country_city<-read.table(sprintf("%s/df_table_occ_country_city.csv", folder), head=T, sep=",", stringsAsFactors = F)}
for (genus in df_genus$genus){
  print(genus)
  if (genus %in% df_table_occ_city$genus){
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
  
  #What % of records per taxa fall within 1km of a city, what % in 2.5km and what % 5km
  city_cuts<-c(0, 1000, 2500, 5000)
  df_occ_city<-df_occ[which(!is.na(df_occ$city_distance)),]
  if (nrow(df_occ_city)==0){
    next()
  }
  df_occ_city$city_cut2<-cut2(df_occ_city$city_distance, city_cuts)
  table_occ_city<-data.frame(table(df_occ_city$city_cut2))
  table_occ_city$genus<-genus
  if (nrow(df_table_occ_city)==0){
    df_table_occ_city<-table_occ_city
  }else{
    df_table_occ_city<-rbind(df_table_occ_city, table_occ_city)
  }
  #What % of records per taxa fall within 2.5km per country
  threshold<-2500
  df_occ_country_city<-df_occ[which(!is.na(df_occ$countryCode)),]
  if (nrow(df_occ_country_city)==0){
    next()
  }
  df_occ_country_city$lower_th<-F
  if (nrow(df_occ_country_city[which(df_occ_country_city$city_distance<=threshold),])>0){
    df_occ_country_city[which(df_occ_country_city$city_distance<=threshold),]$lower_th<-T
  }
  
  table_occ_country<-data.frame(table(df_occ_country_city$countryCode, df_occ_country_city$lower_th))
  table_occ_country<-table_occ_country[which(table_occ_country$Var1!=""),]
  table_occ_country_city<-merge(table_occ_country[which(table_occ_country$Var2==TRUE),],
                             table_occ_country[which(table_occ_country$Var2==FALSE),],
                             by="Var1", all=T)
  table_occ_country_city<-table_occ_country_city[, c("Var1", "Freq.x", "Freq.y")]
  
  colnames(table_occ_country_city)<-c("countryCode", "in_th", "out_th")
  table_occ_country_city[is.na(table_occ_country_city)]<-0
  table_occ_country_city$all<-table_occ_country_city$in_th+table_occ_country_city$out_th
  table_occ_country_city<-table_occ_country_city[order(-table_occ_country_city$all),] 
  table_occ_country_city$genus<-genus
  if (nrow(df_table_occ_country_city)==0){
    df_table_occ_country_city<-table_occ_country_city
  }else{
    df_table_occ_country_city<-rbind(df_table_occ_country_city, table_occ_country_city)
  }

  write.table(df_table_occ_city, sprintf("%s/df_table_occ_city.csv", folder), row.names=F, sep=",")
  write.table(df_table_occ_country_city, sprintf("%s/df_table_occ_country_city.csv", folder), row.names=F, sep=",")
  
}

