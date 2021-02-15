drop_sql<-"DROP TABLE %s_OBIS"
create_sql<-"CREATE TABLE `%s_OBIS` (
  `IDKey` int(11) unsigned NOT NULL,
`date_year` bigint(20) DEFAULT NULL,
`scientificNameID` varchar(500) DEFAULT '',
`scientificName` varchar(500) DEFAULT '',
`scientificNameAuthorship` varchar(50) DEFAULT '',
`absence` tinyint(4) DEFAULT NULL,
`decimalLatitude` double DEFAULT NULL,
`originalScientificName` text,
`marine` tinyint(4) DEFAULT NULL,
`minimumDepthInMeters` bigint(20) DEFAULT NULL,
`occurrenceStatus` varchar(500) DEFAULT '',
`terrestrial` tinyint(4) DEFAULT NULL,
`basisOfRecord` varchar(50) DEFAULT '',
`date_mid` double DEFAULT NULL,
`maximumDepthInMeters` bigint(20) DEFAULT NULL,
`class` varchar(50) DEFAULT '',
`order` varchar(50) DEFAULT '',
`dataset_id` varchar(50) DEFAULT '',
`locality` varchar(50) DEFAULT '',
`decimalLongitude` double DEFAULT NULL,
`date_end` double DEFAULT NULL,
`kingdom` varchar(50) DEFAULT '',
`phylum` varchar(50) DEFAULT '',
`species` varchar(50) DEFAULT '',
`genus` varchar(50) DEFAULT '',
`family` varchar(50) DEFAULT '',
`node_id` varchar(500) DEFAULT '',
`eventDate` varchar(50) DEFAULT '',
`infraclassid` bigint(20) DEFAULT NULL,
`infraclass` varchar(50) DEFAULT '',
`subfamilyid` bigint(20) DEFAULT NULL,
`category` varchar(50) DEFAULT '',
`infraphylum` varchar(50) DEFAULT '',
`infrakingdomid` bigint(20) DEFAULT NULL,
`infraphylumid` bigint(20) DEFAULT NULL,
`superclass` varchar(50) DEFAULT '',
`superclassid` bigint(20) DEFAULT NULL,
`infrakingdom` varchar(50) DEFAULT '',
`subterclassid` bigint(20) DEFAULT NULL,
`subterclass` varchar(50) DEFAULT '',
`section` varchar(50) DEFAULT '',
`infraorderid` bigint(20) DEFAULT NULL,
`subsection` varchar(50) DEFAULT '',
`sectionid` bigint(20) DEFAULT NULL,
`infraorder` varchar(50) DEFAULT '',
`subsectionid` bigint(20) DEFAULT NULL,
`tribeid` bigint(20) DEFAULT NULL,
`tribe` varchar(50) DEFAULT '',
`subgenus` varchar(50) DEFAULT '',
`depth` double DEFAULT NULL,
`subphylum` varchar(50) DEFAULT '',
`subclass` varchar(50) DEFAULT '',
PRIMARY KEY (`IDKey`),
KEY `class` (`class`),
KEY `genus` (`genus`),
KEY `phylum` (`phylum`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
#Class Malacostraca, Phylum Annelida, Class Gastropoda, Class Arachnida (Subphylum Chelicerata), Phylum Cnidaria
#(Classes Elasmobranchii (Chondrichthyes) and Actinopterygii). 

taxa<-c("Class", "Phylum", "Class", "Class", "Phylum", "Class", "Class", "Class", "Class", "Class", "Class")
names<-c("Malacostraca", "Annelida", "Gastropoda", "Arachnida", "Cnidaria", "Elasmobranchii", "Actinopterygii", 
         "Aves", "Amphibia", "Mammalia", "Reptilia")
library("RMySQL")
con <- dbConnect(MySQL(),
                 user="root", password="mikania", port=3306,
                 dbname="gbif", host="127.0.0.1")

sql<-"INSERT INTO %s_OBIS SELECT * FROM OBIS WHERE %s='%s';"
for (i in c(1:length(taxa))){
  print(names[i])
  #dbSendQuery(con, sprintf(drop_sql, names[i]))
  #dbSendQuery(con, sprintf(create_sql, names[i]))
  dbSendQuery(con, sprintf(sql, names[i], taxa[i], names[i]))
}

df<-data.frame()
for (i in c(8:8)){
  print(names[i])
  
  #dbSendQuery(con, sprintf(drop_sql, names[i]))
  #dbSendQuery(con, sprintf(create_sql, names[i]))
  if (names[i]=="Aves"){
    t1<-data.frame(c=553471744)
  }else{
    rs<-dbSendQuery(con, sprintf("SELECT count(1) c from %s", names[i]))
    t1<-fetch(rs, n=-1)
  }
  rs<-dbSendQuery(con, sprintf("SELECT count(1) c from %s_OBIS", names[i]))
  t2<-fetch(rs, n=-1)
  
  item<-data.frame(taxon=taxa[i], name=names[i], c_GBIF=t1$c, c_OBIS=t2$c)
  if (nrow(df)==0){
    df<-item
  }else{
    df<-rbind(df, item)
  }
}
write.table(df, "number_per_group.csv", row.names=F, sep=",")
