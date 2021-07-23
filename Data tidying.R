###########################################################################
#### script to get the data in the appropriate form for running RothC #####
###########################################################################

### Author: Kate Coelli
### Date: 21/07/2021
### Email: kate.coelli@sydney.edu.au

### Required Libraries
library(tidyverse)
library(rgdal)
library(raster)

##############################
######### Site Data ##########
##############################


### Farm boundary
boundary<- readOGR("Data/boundary/Oodnadatta.shp")


### Soil data
soil_data<- read.csv("Data/soil_data.csv")
soil_data$DepthMin.cm.<- as.numeric(soil_data$DepthMin.cm.)
soil_data$DepthMax.cm.<- as.numeric(soil_data$DepthMax.cm.)

#select relevant variables
soil_data<- soil_data%>%
  select(Longitude, Latitude, Sample.ID, Field, Sample.Date, Season, DepthMin.cm., DepthMax.cm., Soil.Clay....., Soil.Sand....., S.TOC.16)%>%
  filter(between(DepthMin.cm., 0, 15))

##############################
####### Gridded Data #########
##############################

### Carbon stocks - Made by Pat
carbon_stock_raster<- raster("Data/carbon_stock_0_30.tif")

### Yield maps

sorghum_2021<- raster("Data/OD01_2021_sorghum.tiff")
barley_2020<- raster("Data/OD02_2020_barley.tiff")
wheat_2020_OD03<- raster("Data/OD03_2020_wheat.tiff")
wheat_2020_OD04<-raster("Data/OD04_2020_wheat.tiff")
chickpea_2020<- raster("Data/OD05_2020_chickpea.tiff")






###### ADD SOME RANDOM STUFF TO THIS SCRIPT TO SEE HOW IT WORKS



