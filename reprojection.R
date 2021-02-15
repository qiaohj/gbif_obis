setwd("/Volumes/Disk2/Experiments/Huijie/Script")
library(raster)
road<-raster("../Raster/minrodist_p1.tif")
biome<-raster("../Raster/biome_number1b.tif")

bionew<-projectRaster(biome, road, res=res(road), crs=crs(road), method="ngb")
unique(values(bionew))


writeRaster(bionew, "../Raster/biome_number1b_lonlat.tif")
#p_road<-data.frame(rasterToPoints(road))
#p_road<-SpatialPoints(p_road[, c("x", "y")], proj4string=crs(road))
#p_road_reproj<-spTransform(p_road, crs(biome))
#p_road_reproj_df<-data.frame(p_road_reproj)
#head(p_road_reproj_df)
#p_road_reproj_df$biome<-extract(biome, p_road_reproj_df)

coast<-raster("../Raster/coast_km11.tif")
coastnew<-projectRaster(coast, road, res=res(road), crs=crs(road), method="bilinear")
writeRaster(coastnew, "../Raster/coast_km11_lonlat.tif")

river_dist11<-raster("../Raster/river_dist11.tif")
river_dist11new<-projectRaster(river_dist11, road, res=res(road), crs=crs(road), method="bilinear")
writeRaster(river_dist11new, "../Raster/river_dist11_lonlat.tif")

pa<-raster("../Raster/pa.tif")
panew<-projectRaster(pa, road, res=res(road), crs=crs(road), method="ngb")
writeRaster(panew, "../Raster/pa_lonlat.tif")

nightlight<-raster("../Raster/Clip_nitliggrey2.tif")
crs(nightlight)<-crs(road)
nightlightnew<-projectRaster(nightlight, road, res=res(road), crs=crs(road), method="bilinear")
writeRaster(nightlightnew, "../Raster/nightlight_lonlat.tif")


pa2<-raster("../Raster/wdpa/wdpa_A191.tif")
pa2new<-projectRaster(pa2, road, res=res(road), crs=crs(road), method="ngb")
writeRaster(pa2new, "../Raster/pa2_lonlat.tif", overwrite=T)


bio1<-raster("../Raster/Bioclim2.0/wc2.0_bio_30s_01.tif")
bio1new<-projectRaster(bio1, road, res=res(road), crs=crs(road), method="bilinear")
writeRaster(bio1new, "../Raster/bio1_lonlat.tif", overwrite=T)


bio12<-raster("../Raster/Bioclim2.0/wc2.0_bio_30s_12.tif")
bio12new<-projectRaster(bio12, road, res=res(road), crs=crs(road), method="bilinear")
writeRaster(bio12new, "../Raster/bio12_lonlat.tif", overwrite=T)

citydistance<-raster("../Raster/citydistance/city_distance.tif")
citydistancenew<-projectRaster(citydistance, road, res=res(road), crs=crs(road), method="bilinear")
writeRaster(citydistancenew, "../Raster/city_lonlat.tif", overwrite=T)
plot(citydistancenew)



library(rgdal)
oceanrealm<-rgdal::readOGR(dsn="../Raster/MarineRealmsShapeFile", layer="MarineRealms")
pgeo <- spTransform(oceanrealm, crs(road))

rr <- rasterize(pgeo, road, field="Realm")
rr
plot(rr)
writeRaster(rr, "../Raster/MarineRealms.tif")




ress<-seq(0, 1, by=0.05)
ress[1]<-0.01
ress[2]<-0.045

mask<-raster("../Raster/mask_continent_10km.tif")
res<-1
for (res in rev(ress)){
  print(res)
  r<-mask
  res(r)<-c(res, res)
  r<-resample(mask, r)
  no_na<-!is.na(values(r))
  values(r)[no_na]<-c(1:length(no_na[no_na]))
  writeRaster(r, sprintf("../Raster/mask_continent_%.2f.tif", res), dataType="INT4U")
}

mask<-raster("../Raster/mask_ocean_10km.tif")
res<-1
for (res in rev(ress)){
  print(res)
  r<-mask
  res(r)<-c(res, res)
  r<-resample(mask, r)
  no_na<-!is.na(values(r))
  values(r)[no_na]<-c(1:length(no_na[no_na]))
  writeRaster(r, sprintf("../Raster/mask_ocean_%.2f.tif", res), dataType="INT4U")
}


