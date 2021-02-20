library(ggplot2)
library(data.table)
ress<-seq(0, 1, by=0.05)
ress[1]<-0.01
ress[2]<-0.045
classes<-c("Actinopterygii", "Amphibia", "Annelida", "Arachnida", "Aves", "Cnidaria",
           "Elasmobranchii", "Gastropoda", "Malacostraca", "Mammalia", "Reptilia")
class<-"Cnidaria"
df_all<-NULL
for (class in classes){
  df<-readRDS(sprintf("../Data/Coverage/%s.rda", class))
  if (is.null(df_all)){
    df_all<-df
  }else{
    df_all<-rbind(df_all, df)
  }
}

colors<-c("Actinopterygii"="blue4",
          "Amphibia"="brown",
          "Annelida"="brown1",
          "Arachnida"="chocolate",
          "Aves"="burlywood",
          "Cnidaria"="cadetblue4",
          "Elasmobranchii"="darkgreen",
          "Gastropoda"="darkorchid",
          "Malacostraca"="black",
          "Mammalia"="deeppink",
          "Reptilia"="deeppink4")

library(randomcoloR)
library(RColorBrewer)

n <- 11
#palette <- distinctColorPalette(n, altCol=F, runTsne=T)

palette<-brewer.pal(n = 11, name = 'Paired')

names(palette)<-classes

p<-ggplot(df_all)+
  geom_line(aes(x=res, y=coverage_proportion, 
                color=group, linetype=factor(type)), size=1)+
  labs(color="Group", linetype="")+
  scale_color_manual(values=palette)+
  #facet_wrap(~type)+
  xlab("Resolution")+
  ylab("Spatial coverage")+
  theme_bw()
ggsave(p, filename="../Figures/coverage.pdf")
write.table(df_all, "../Figures/coverage.csv", row.names = F, sep=",")
df_all<-data.table(df_all)
df_all[group=="Amphibia"]


classes<-c("Actinopterygii", "Amphibia", "Annelida", "Arachnida", "Aves", "Cnidaria",
           "Elasmobranchii", "Gastropoda", "Malacostraca", "Mammalia", "Reptilia")
class<-"Cnidaria"
df_all<-NULL
for (class in classes){
  df<-readRDS(sprintf("../Data/Coverage/SAR_%s.rda", class))
  if (is.null(df_all)){
    df_all<-df
  }else{
    df_all<-rbind(df_all, df)
  }
}

df_all$per<-df_all$N_SP/df_all$all_N_target_SP
ggplot(df_all)+geom_line(aes(x=threshold, y=per, color=group, linetype=factor(type)))+
  facet_wrap(~res)


p<-ggplot(df_all[res==0.1])+geom_line(aes(x=threshold, y=per * 100, color=group, linetype=factor(type)))+
  scale_color_manual(values=palette)+
  scale_x_continuous(breaks = seq(0, 100, 10))+
  theme_bw()+
  labs(color="Group", linetype="")+
  xlab("Proportion of sampled area (%)")+
  ylab("Proportion of sampled species (%)")+
  geom_text(aes(x=80, y=10, label="Resolution: 10km"), size=3)
p
ggsave(p, filename="../Figures/SAR_10km.pdf", width=7, height=5)
p<-ggplot(df_all[res==1])+geom_line(aes(x=threshold, y=per * 100, color=group, linetype=factor(type)))+
  scale_color_manual(values=palette)+
  scale_x_continuous(breaks = seq(0, 100, 10))+
  theme_bw()+
  labs(color="Group", linetype="")+
  xlab("Proportion of sampled area (%)")+
  ylab("Proportion of sampled species (%)")+
  geom_text(aes(x=80, y=10, label="Resolution: 100km"), size=3)
p
ggsave(p, filename="../Figures/SAR_100km.pdf", width=7, height=5)

write.table(df_all, "../Figures/sar.csv", row.names = F, sep=",")
