setwd("/Volumes/Disk2/Experiments/Huijie/Script")

library("RMySQL")
con <- dbConnect(MySQL(),
                 user="root", password="mikania", port=3306,
                 dbname="gbif", host="127.0.0.1")

rs<-dbSendQuery(con, "SHOW Tables")
tables<-fetch(rs, n=-1)
table<-tables$Tables_in_gbif[10]
for (table in tables$Tables_in_gbif){
  if (grepl("OBIS_", table)){

    print(table)
    colnames<-"scientificNameID,decimalLatitude,minimumDepthInMeters,maximumDepthInMeters,class,`order`,decimalLongitude,kingdom,phylum,subphylum, subclass,genus,family,node_id,depth"
    sql<-sprintf("INSERT INTO OBIS (%s) SELECT %s FROM %s", colnames, colnames, table)
    rs<-dbSendQuery(con, sql)
  }
}
