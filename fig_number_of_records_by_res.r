library(ggplot2)
ress<-seq(0, 1, by=0.05)
ress[1]<-0.01
ress[2]<-0.045
classes<-c("Actinopterygii", "Amphibia", "Annelida", "Arachnida", "Aves", "Cnidaria",
           "Elasmobranchii", "Gastropoda", "Malacostraca", "Mammalia", "Reptilia")
class<-"Cnidaria"
for (class in classes){
  df<-readRDS(sprintf("../Data/Coverage/%s.rda", class))
}

ggplot(df)+geom_line(aes(x=res, y=coverage_proportion, color=factor(group), linetype=factor(type)))
