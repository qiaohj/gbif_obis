
setwd("/Volumes/Disk2/Experiments/Huijie/Script")
library("RMySQL")

con<-dbConnect(MySQL(), user="root", password="mikania", 
               dbname="gbif", host="127.0.0.1")

rs<-dbSendQuery(con, "SELECT DISTINCT phylum FROM OBIS")

phylum<-fetch(rs, n=-1)


collist<-c("scientificNameID", "genus", "decimalLatitude", "decimalLongitude")

for (phyla in phylum$phylum){
  if (is.na(phyla)){
    next()
  }
  dir.create(sprintf("../obis/%s", phyla), mode="0777", recursive=T, showWarnings = F)

  rs<-dbSendQuery(con, sprintf("SELECT DISTINCT genus FROM OBIS WHERE phylum='%s'", phyla))
  groups<-fetch(rs, n=-1)
  
  
  for (i in c(1:nrow(groups))){
    group<-groups[i,]
    if (is.na(group)){
      next()
    }
    print(paste(group, i, nrow(groups)))
    if (group==""){
      next()
    }
    
    t_file<-sprintf("/Volumes/Disk2/Experiments/Huijie/obis/%s/export_%s.csv", phyla, group)
    if (file.exists(t_file)){
      next()
    }
    sql<-sprintf("SELECT %s FROM OBIS WHERE phylum='%s' and genus='%s' INTO OUTFILE '%s' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n';", 
                 paste(collist, collapse=","), phyla, group, t_file)
    dbSendQuery(con, sql)
  }
}


#check the data
#df<-read.table("/Volumes/DATA/export_Corvus.csv", head=T, sep=",")
