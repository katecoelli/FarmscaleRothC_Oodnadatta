###########################################################################
#### script to get the data in the appropriate form for running RothC #####
###########################################################################

### Author: Kate Coelli
### Date: 21/07/2021
### Email: kate.coelli@sydney.edu.au


# Soil Data - dataframe which contains the following variables
# SOC
# POC (RPM in RothC)
# HOC (HUM in RothC)
# ROC (IOM in RothC)
# Sand %
# Clay %
# Field Capacity
# Date of sampling - Need to talk to Tom about this for long ambiguous surveys


### Required Libraries
library(tidyverse)
library(rgdal)
library(raster)
library(mapview)

### CRS
GDA94_latlong = CRS("+init=epsg:4283")
GDA94_xy_55 = CRS("+init=epsg:28355")
GDA94_xy_56 = CRS("+init=epsg:28356")

### Required Functions
source("../../../R/soil_carbon_modelling_phd/useful_functions/Soil related functions.R")

##############################
######### Site Data ##########
##############################


### Farm boundary
boundary<- readOGR("../Data/boundary/Oodnadatta.shp")


### Soil data
soil_data<- read.csv("../Data/soil_data.csv")
soil_data$DepthMin.cm.<- as.numeric(soil_data$DepthMin.cm.)
soil_data$DepthMax.cm.<- as.numeric(soil_data$DepthMax.cm.)

#sample locations
sample_locations<- SpatialPointsDataFrame(soil_data[1:2], soil_data, proj4string = GDA94_latlong)
writeOGR(sample_locations, dsn="../Processed_Data/Oodnadatta_locations", layer ="Oodnadatta_locations", driver = "ESRI Shapefile")

#select relevant variables
soil_data<- soil_data%>%
  dplyr::select(Longitude, Latitude, Sample.ID, Field, Sample.Date, DepthMin.cm., DepthMax.cm., Soil.Clay....., Soil.Sand....., S.TOC.16)%>%
  filter(between(DepthMin.cm., 0, 15))

colnames(soil_data)[6:10]<- c("Upper", "Lower", "Clay", "Sand", "SOC")


##############################
####### Gridded Data #########
##############################

### Fraction Maps
## These fraction maps are from Jon Gray et al 2019

ROC<-raster("../../NSW_extent_data/SOC_fractions_Gray/ROCtph0_30_boot_mean_gda 190305.tif")
HOC<- raster("../../NSW_extent_data/SOC_fractions_Gray/HOCtph0_30_boot_mean_gda 190305.tif")
POC<-raster("../../NSW_extent_data/SOC_fractions_Gray/POCtph0_30_boot_mean_final_gda_190305.tif")


#extract fractions
soil_data$ROC<- raster::extract(ROC, soil_data[1:2])
soil_data$HOC<- raster::extract(HOC, soil_data[1:2])
soil_data$POC<- raster::extract(POC, soil_data[1:2])

######################
####### tidy #########
######################


#Convert from 2 depths to 1 depth 
soil_data_final<-soil_data%>%
  group_by(Sample.ID, Field)%>%
  mutate(SOC_0to30= sum(SOC)/2)%>%
  mutate(sand_0to30= sum(Sand)/2)%>%
  mutate(clay_0to30= sum(Clay)/2)%>%
  ungroup()%>%
  dplyr::select(-Upper, -Lower, -Clay, -Sand, -SOC)%>%
  rename(SOC=SOC_0to30, Sand = sand_0to30, Clay = clay_0to30)

soil_data_final<- unique(soil_data_final)

#calculate BD and convert SOC (%) to stocks (t/ha)
soil_data_final<- soil_data_final%>%
  mutate(BD=bd_glob(SOC, Van_Bemelen_factor, Sand, mid_depth= 15))%>%
  mutate(SOC=SOC*30*BD) #SOC(%)*BD*depth(cm)



####################################
####### Final Soil Data df #########
####################################


soil_data_final<- soil_data_final%>%
  mutate(ID=paste0(Field, "_", Sample.ID))%>%
  mutate(Year = substr(Sample.Date, start=nchar(Sample.Date)-3, stop = nchar(Sample.Date)-0))%>%
  dplyr::select(Longitude, Latitude, ID, Year, Sample.Date, everything(), -Sample.ID, -Field, -BD)


write_csv(soil_data_final, "../Processed_Data/soil_data_0to30.csv")
