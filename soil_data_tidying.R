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
source("../../../../useful_functions/Soil related functions.R")

##############################
######### Site Data ##########
##############################


### Farm boundary
boundary<- readOGR("../../../../Data/Farms/Oodnadatta/boundary/Oodnadatta.shp")


### Soil data
#read in original data
soil_data<- read.csv("../../../../Data/Farms/Oodnadatta/soil_data.csv")
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

ROC<-raster("../../../../Data/NSW_extent_data/SOC_fractions_Gray/ROCtph0_30_boot_mean_gda 190305.tif")
HOC<- raster("../../../../Data/NSW_extent_data/SOC_fractions_Gray/HOCtph0_30_boot_mean_gda 190305.tif")
POC<-raster("../../../../Data/NSW_extent_data/SOC_fractions_Gray/POCtph0_30_boot_mean_final_gda_190305.tif")


#extract fractions
soil_data$ROC<- raster::extract(ROC, soil_data[1:2])
soil_data$HOC<- raster::extract(HOC, soil_data[1:2])
soil_data$POC<- raster::extract(POC, soil_data[1:2])

######################
####### tidy #########
######################

#soil depth
depth = 30 #depth in cm

#Convert from 2 depths to 1 depth 
soil_data_tidy<-soil_data%>%
  group_by(Sample.ID, Field)%>%
  mutate(SOC_0to30= sum(SOC)/2)%>%
  mutate(sand_0to30= sum(Sand)/2)%>%
  mutate(clay_0to30= sum(Clay)/2)%>%
  ungroup()%>%
  dplyr::select(-Upper, -Lower, -Clay, -Sand, -SOC)%>%
  rename(SOC=SOC_0to30, Sand = sand_0to30, clay = clay_0to30)%>%
  unique()

#calculate Field Capacity using function
soil_data_tidy<- soil_data_tidy%>%
  mutate(FC=FC(Sand,clay))%>%
  mutate(bucket_size = FC * depth * 10)

#calculate BD and convert SOC (%) to stocks (t/ha)
soil_data_tidy<- soil_data_tidy%>%
  mutate(BD=bd_glob(SOC, Van_Bemelen_factor, Sand, mid_depth= 15))%>%
  mutate(SOC=SOC*30*BD) #SOC(%)*BD*depth(cm)



####################################
####### Final Soil Data df #########
####################################


soil_data_final<- soil_data_tidy%>%
  mutate(ID=paste0(Field, "_", Sample.ID))%>%
  dplyr::select(Longitude, Latitude, ID, Sample.Date, everything(), -Sample.ID, -Field, -BD)%>%
  mutate(year = substr(Sample.Date, nchar(Sample.Date)-3, nchar(Sample.Date)))



# NB - do not include fractions because they will be determined for each site in the equil. run


#######################################################
####### Final Soil Data for RothC Equilibrium #########
#######################################################

soil_data_equil<- soil_data_final%>%
  select(-HOC, -POC, -Sand, -FC, -bucket_size, -year)

write_csv(soil_data_final, "../Processed_Data/soil_data_equil.csv")




##############################################
####### Final Soil Data for RothC RT #########
##############################################

#NB THIS CAN ONLY OCCUR ONCE EQUIL RUN HAS HAPPENED

#Select required data for RT RothC run - ensure correct column names
  #site_id
  #year
  #TOC
  #RPM
  #HUM
  #IOM
  #depth
  #bucket_size
  #clay

fractions<- read.csv("../Processed_Data/fractions_for_initialisation.csv") #this file created in equilibrium run RMD

soil_data_RT<- soil_data_final%>%
  add_column(depth = 30)%>%
  select(ID, year, SOC, bucket_size, clay)%>%
  full_join(fractions[,c("ID", "RPM", "HUM", "IOM")])%>%
  rename(site_id=ID, TOC = SOC)
  
soil_data_RT$depth<- 30  

write_csv(soil_data_RT, "../Processed_Data/soil_data_RT.csv")



