###################################################################################
#### script to get the monthly data in the appropriate form for running RothC #####
##################################################################################

### Author: Kate Coelli
### Date: 23/07/2021
### Email: kate.coelli@sydney.edu.au
### Details: 
# This file provides instruction for calculating Long Term Monthly climate data required for running RothC in Equilibrium Mode.
# This website provides a useful guide to running RothC in equilibrium mode using the SoilR package from R
# https://www.bgc-jena.mpg.de/TEE/basics/2015/11/19/RothC/


### Required Libraries and functions
library(tidyverse)
library(raster)
library(rgdal)
library(doParallel)
library(rgeos)
# library(sf)
# library(readr)
# library(zoo)
library(lubridate)
library(ncdf4)
# library(sp)
library(rlang)
# library(DescTools)

source("../../../../Useful_functions/data_prep_and_params_optimisatn_functions.R")

### Site Information

## Import polygon of region of interest
# This could be a farm, catchment, state, country etc

boundary<- readOGR("../../../../Data/Farms/Oodnadatta/boundary/Oodnadatta.shp")


# Find centre of region - as farm is fairly small in a climate context we are using one point in the centre of the farm as the climate reference.
# Please note, if you are using this code for a larger area, you may wish to consider using all the gridded climate data included within your "boundary"

sitename<- as.data.frame("middlepoint")
colnames(sitename)<- "site_id"

extract_locations<- gCentroid(boundary)
extract_locations<- SpatialPointsDataFrame(extract_locations, sitename)
  
  #this file needs to be a spatial points dataframe and "site_id" column needs to be in the dataframe

# Plot to check extract location
plot(boundary)
points(extract_locations, pch = 16, col = "blue")

#load in soil data information

soil_data<- read.csv("../Processed_Data/soil_data_equil.csv")


sample_date<- as.numeric(substr(soil_data[1, "Sample.Date"])) #Here we assume all sampling dates are the same and just take the first date to determine year of sampling
# then we collect 30 years of climate data prior to and including sampling year 

## Daily Climate Data from SILO
# All climate data has been downloaded as SILO gridded data <https://www.longpaddock.qld.gov.au/silo/gridded-data/>.
# The variables extracted include rainfall, min and max temperatures, and pan evaporation.
# These are .nc files for each year for the 30 years prior to and including sampling year

# NB It is really important to include full.names = T argument in list.files to ensure full file path is included.

climate_files<- list.files("../../../../Data/Australia_extent_data/SILO_gridded/", pattern = ".nc", full.names = T)

### Extract climate data at locations
#This code chunk is adapted from code from Sabastine's code as part of the RothC project

clim_vars <- c("daily_rain", "evap_pan", "min_temp", "max_temp")

registerDoParallel(cores = 4)

#these packages need to be loaded and on windows, specified to work
foreach_packages<- c("raster",
                     "tidyverse",
                     "lubridate",
                     "rlang")

climate_data <- foreach(i = seq_along(clim_vars), .combine = cbind, .packages= foreach_packages) %dopar% {
  extract_clim_vars(climate_files, clim_vars[i], extract_locations)
}

### Calculate long term average of climate data
  
climate_data_processed <- climate_data %>%
  rename(rain = "daily_rain",
         evap = "evap_pan",
         min_temp = "min_temp",
         max_temp = "max_temp") %>%
  rowwise() %>%
  mutate(mean_temp = mean(c_across(c(min_temp, max_temp)))) %>%
  dplyr::select(-c(min_temp, max_temp))%>%
  # at this point it is monthly data for the entire period 
  mutate(yr = as.numeric(substr(date, 1, 4)))%>%
  dplyr::filter(between(yr, sample_date-30, sample_date))#30 years prior to and including year of sampling

long_term_climate_data<-climate_data_processed%>%
  mutate(month = as.numeric(substr(date, 6, 8)))%>%
  group_by(month)%>%
  summarise(LTA_rain = mean(rain), LTA_temp= mean(mean_temp), LTA_evap=mean(evap))

write.csv(long_term_climate_data, "../Processed_Data/LTA_climate_data.csv", row.names = FALSE)
