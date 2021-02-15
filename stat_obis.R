setwd("/Volumes/Disk2/Experiments/Huijie/Script")
library(raster)
library(Hmisc)
library(ggplot2)
library(RMySQL)
rm(list=ls())

con<-dbConnect(MySQL(), user="root", password="mikania", 
               dbname="gbif", host="127.0.0.1")

sql<-"select count(1) c, phylum, genus from obis group by phylum, genus"
rs<-dbSendQuery(con, sql)
df<-fetch(rs, n=-1)

tail(df)

range(df$c)
write.table(df, "stat_obis_genus.csv", row.names = F, sep = ",")


con<-dbConnect(MySQL(), user="root", password="mikania", 
               dbname="gbif", host="127.0.0.1")

sql<-"select count(1) c, phylum from obis group by phylum"
rs<-dbSendQuery(con, sql)
df<-fetch(rs, n=-1)

tail(df)

range(df$c)
write.table(df, "stat_obis_phylum.csv", row.names = F, sep = ",")
