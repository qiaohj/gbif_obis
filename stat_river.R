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
new<-T
if (new){
  df_table_occ_river<-data.frame()
  df_table_occ_country_river<-data.frame()
  df_table_occ_pa_river<-data.frame()
  
  df_table_occ_coast<-data.frame()
  df_table_occ_country_coast<-data.frame()
  df_table_occ_pa_coast<-data.frame()
  
}
folder<-sprintf("stat/%s", class)
if (!dir.exists(folder)){
  dir.create(folder)
}
if (!new){
  df_table_occ_river<-read.table(sprintf("%s/df_table_occ_river.csv", folder), head=T, sep=",", stringsAsFactors = F)
  df_table_occ_country_river<-read.table(sprintf("%s/df_table_occ_country_river.csv", folder), head=T, sep=",", stringsAsFactors = F)
  df_table_occ_pa_river<-read.table(sprintf("%s/df_table_occ_pa_river.csv", folder), head=T, sep=",", stringsAsFactors = F)
  
  df_table_occ_coast<-read.table(sprintf("%s/df_table_occ_coast.csv", folder), head=T, sep=",", stringsAsFactors = F)
  df_table_occ_country_coast<-read.table(sprintf("%s/df_table_occ_country_coast.csv", folder), head=T, sep=",", stringsAsFactors = F)
  df_table_occ_pa_coast<-read.table(sprintf("%s/df_table_occ_pa_coast.csv", folder), head=T, sep=",", stringsAsFactors = F)
}
for (genus in df_genus$genus){
  print(genus)
  if (genus %in% df_table_occ_river$genus){
    next()
  }
  target<-sprintf("../occ_gbif/%s/export_%s.csv", class, genus)
  if (!file.exists(target)){
    next()
  }
  df_occ<-read.table(target, head=T, sep=",", stringsAsFactors = F, quote = "\"")
#-----------------RIVER------------------------------
  #What % of records per taxa fall within 1km of a river, what % in 2.5km and what % 5km
  river_cuts<-c(0, 1000, 2500, 5000)
  df_occ_river<-df_occ[which(!is.na(df_occ$river)),]
  if (nrow(df_occ_river)==0){
    next()
  }
  df_occ_river$river_cut2<-cut2(df_occ_river$river, river_cuts)
  table_occ_river<-data.frame(table(df_occ_river$river_cut2))
  table_occ_river$genus<-genus
  if (nrow(df_table_occ_river)==0){
    df_table_occ_river<-table_occ_river
  }else{
    df_table_occ_river<-rbind(df_table_occ_river, table_occ_river)
  }
  #What % of records per taxa fall within 2.5km per country
  threshold<-2500
  df_occ_country_river<-df_occ[which(!is.na(df_occ$countryCode)),]
  if (nrow(df_occ_country_river)==0){
    next()
  }
  df_occ_country_river$lower_th<-F
  if (nrow(df_occ_country_river[which(df_occ_country_river$river<=threshold),])>0){
    df_occ_country_river[which(df_occ_country_river$river<=threshold),]$lower_th<-T
  }
  
  table_occ_country<-data.frame(table(df_occ_country_river$countryCode, df_occ_country_river$lower_th))
  table_occ_country<-table_occ_country[which(table_occ_country$Var1!=""),]
  table_occ_country_river<-merge(table_occ_country[which(table_occ_country$Var2==TRUE),],
                             table_occ_country[which(table_occ_country$Var2==FALSE),],
                             by="Var1", all=T)
  table_occ_country_river<-table_occ_country_river[, c("Var1", "Freq.x", "Freq.y")]
  
  colnames(table_occ_country_river)<-c("countryCode", "in_th", "out_th")
  table_occ_country_river[is.na(table_occ_country_river)]<-0
  table_occ_country_river$all<-table_occ_country_river$in_th+table_occ_country_river$out_th
  table_occ_country_river<-table_occ_country_river[order(-table_occ_country_river$all),] 
  table_occ_country_river$genus<-genus
  if (nrow(df_table_occ_country_river)==0){
    df_table_occ_country_river<-table_occ_country_river
  }else{
    df_table_occ_country_river<-rbind(df_table_occ_country_river, table_occ_country_river)
  }
  
  #What % of records falls within 2.5km of a river inside a Protected area vs outside a protected area
  
  df_occ_pa_river<-df_occ_country_river[which(!is.na(df_occ_country_river$pa)),]
  if (nrow(df_occ_pa_river)==0){
    next()
  }
  
  table_occ_pa_river<-data.frame(table(df_occ_pa_river$pa, df_occ_pa_river$lower_th))
  colnames(table_occ_pa_river)<-c("is_pa", "in_th", "Freq")
  table_occ_pa_river$genus<-genus
  if (nrow(df_table_occ_pa_river)==0){
    df_table_occ_pa_river<-table_occ_pa_river
  }else{
    df_table_occ_pa_river<-rbind(df_table_occ_pa_river, table_occ_pa_river)
  }
  
  write.table(df_table_occ_river, sprintf("%s/df_table_occ_river.csv", folder), row.names=F, sep=",")
  write.table(df_table_occ_country_river, sprintf("%s/df_table_occ_country_river.csv", folder), row.names=F, sep=",")
  write.table(df_table_occ_pa_river, sprintf("%s/df_table_occ_pa_river.csv", folder), row.names=F, sep=",")
  
  #-----------------COAST------------------------------
  #What % of records per taxa fall within 1km of a coast, what % in 2.5km and what % 5km
  coast_cuts<-c(0, 1000, 2500, 5000)
  df_occ_coast<-df_occ[which(!is.na(df_occ$coast)),]
  if (nrow(df_occ_coast)==0){
    next()
  }
  df_occ_coast$coast_cut2<-cut2(df_occ_coast$coast, coast_cuts)
  table_occ_coast<-data.frame(table(df_occ_coast$coast_cut2))
  table_occ_coast$genus<-genus
  if (nrow(df_table_occ_coast)==0){
    df_table_occ_coast<-table_occ_coast
  }else{
    df_table_occ_coast<-rbind(df_table_occ_coast, table_occ_coast)
  }
  #What % of records per taxa fall within 2.5km per country
  threshold<-2500
  df_occ_country_coast<-df_occ[which(!is.na(df_occ$countryCode)),]
  if (nrow(df_occ_country_coast)==0){
    next()
  }
  df_occ_country_coast$lower_th<-F
  if (nrow(df_occ_country_coast[which(df_occ_country_coast$coast<=threshold),])>0){
    df_occ_country_coast[which(df_occ_country_coast$coast<=threshold),]$lower_th<-T
  }
  
  table_occ_country<-data.frame(table(df_occ_country_coast$countryCode, df_occ_country_coast$lower_th))
  table_occ_country<-table_occ_country[which(table_occ_country$Var1!=""),]
  table_occ_country_coast<-merge(table_occ_country[which(table_occ_country$Var2==TRUE),],
                                 table_occ_country[which(table_occ_country$Var2==FALSE),],
                                 by="Var1", all=T)
  table_occ_country_coast<-table_occ_country_coast[, c("Var1", "Freq.x", "Freq.y")]
  
  colnames(table_occ_country_coast)<-c("countryCode", "in_th", "out_th")
  table_occ_country_coast[is.na(table_occ_country_coast)]<-0
  table_occ_country_coast$all<-table_occ_country_coast$in_th+table_occ_country_coast$out_th
  table_occ_country_coast<-table_occ_country_coast[order(-table_occ_country_coast$all),] 
  table_occ_country_coast$genus<-genus
  if (nrow(df_table_occ_country_coast)==0){
    df_table_occ_country_coast<-table_occ_country_coast
  }else{
    df_table_occ_country_coast<-rbind(df_table_occ_country_coast, table_occ_country_coast)
  }
  
  
  
  #What % of records falls within 2.5km of a coast inside a Protected area vs outside a protected area
  
  df_occ_pa_coast<-df_occ_country_coast[which(!is.na(df_occ_country_coast$pa)),]
  if (nrow(df_occ_pa_coast)==0){
    next()
  }
  
  table_occ_pa_coast<-data.frame(table(df_occ_pa_coast$pa, df_occ_pa_coast$lower_th))
  colnames(table_occ_pa_coast)<-c("is_pa", "in_th", "Freq")
  table_occ_pa_coast$genus<-genus
  if (nrow(df_table_occ_pa_coast)==0){
    df_table_occ_pa_coast<-table_occ_pa_coast
  }else{
    df_table_occ_pa_coast<-rbind(df_table_occ_pa_coast, table_occ_pa_coast)
  }
  
  
  write.table(df_table_occ_coast, sprintf("%s/df_table_occ_coast.csv", folder), row.names=F, sep=",")
  write.table(df_table_occ_country_coast, sprintf("%s/df_table_occ_country_coast.csv", folder), row.names=F, sep=",")
  write.table(df_table_occ_pa_coast, sprintf("%s/df_table_occ_pa_coast.csv", folder), row.names=F, sep=",")
}

