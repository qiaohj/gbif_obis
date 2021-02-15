args = commandArgs(trailingOnly=TRUE)
class<-args[1]

setwd(sprintf("/Volumes/Disk2/Experiments/Huijie/raw_gbif/%s", class))
library("RMySQL")

con<-dbConnect(MySQL(), user="root", password="mikania", 
               dbname="gbif", host="127.0.0.1")

collist<-c("species", "genus", "decimalLatitude", "decimalLongitude", "month", "year", "countryCode", 
           "institutionCode", "coordinateUncertaintyInMeters", "coordinatePrecision", "basisOfRecord")
group<-'Passer'
rs<-dbSendQuery(con, sprintf("SELECT DISTINCT genus FROM %s", class))
groups<-fetch(rs, n=-1)


for (i in c(1:nrow(groups))){
  group<-groups[i,]
  print(paste(group, i, nrow(groups)))
  if (group==""){
    next()
  }
  dir.create(sprintf("/Volumes/Disk2/Experiments/Huijie/gbif/%s", class))
  t_file<-sprintf("/Volumes/Disk2/Experiments/Huijie/gbif/%s/export_%s.csv", class, group)
  if (file.exists(t_file)){
    next()
  }
  sql<-sprintf("SELECT %s FROM %s WHERE genus='%s' INTO OUTFILE '%s' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n';", 
               paste(collist, collapse=","), class, group, t_file)
  dbSendQuery(con, sql)
}



#check the data
#df<-read.table("/Volumes/DATA/export_Corvus.csv", head=T, sep=",")
