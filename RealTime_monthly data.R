###################################################################################
#### script to get the monthly data in the appropriate form for running RothC #####
##################################################################################

### Author: Kate Coelli
### Date: 26/07/2021
### Email: kate.coelli@sydney.edu.au

### Required Libraries
library(tidyverse)
library(rgdal)
library(raster)
library(SoilR)

### This website provides a useful guide
# https://www.bgc-jena.mpg.de/TEE/basics/2015/11/19/RothC/


# Site Information
location <- "Oodnadatta" #this is the farm, catchment, state, region etc where the sites are


### Inputs
# For equilibrium runs, to initialize the carbon pools in RothC, we use longterm average data
# In this case, we used the 20 Years prior to the Year in which we had SOC samples

#Data requirements

# - The Monthly data are:

# 1. Evapotranspiration (ET): This data is derived from the 8-day MODIS ET. In processing we disaggregated the data to
# daily values and then compute the monthly sum from the daily data. The Script can be found here:
# https://code.earthengine.google.com/?scriptPath=users%2FPhD_research%2FRothC%3AET_extraction
# Column headings are dates: format = D/MM/YYYY
# Rows are unique sites
# aggregated to monthly at a later point.

# 2. Climate data: The climate data is from the SILO climate files. The variables extracted include rainfall,
# min and max temperatures, and pan evapotranspiration.
# These are .nc files for each year in the run period

# 3.Plant Inputs: 



####################################
############# Climate ##############
####################################

### Temperature


### Rainfall


### Evapotranspiration 



### Yield maps

sorghum_2021<- raster("Data/OD01_2021_sorghum.tiff")
barley_2020<- raster("Data/OD02_2020_barley.tiff")
wheat_2020_OD03<- raster("Data/OD03_2020_wheat.tiff")
wheat_2020_OD04<-raster("Data/OD04_2020_wheat.tiff")
chickpea_2020<- raster("Data/OD05_2020_chickpea.tiff")





Temperature<- 
