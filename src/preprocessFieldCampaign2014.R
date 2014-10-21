#  Pre-process 2014 field campaign data sets
#
#  Copyright (C) 2014 Vanessa Wilzek, Alice Ziegler, Thomas Nauss
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#  Please send any comments, suggestions, criticism, or (for our sake) bug
#  reports to admin@environmentalinformatics-marburg.de
#
#  Details
#  The script merges several csv files and adds geo-location information.
#  To run the script, adjust the following variables (if no one else did it
#  for you):
#  inpath - full path to the top level input folder
#  top_level_outpath - full path to the output folder
#  proj_out - proj4 string of the target projection (see web pages above)
#  
#  NOTE: DO NOT USE A TOP LEVEL OUTPUT PATH WHICH IS INSIDE THE TOP LEVEL INPUT
#        PATH

#### User setttings ############################################################
inpath <- "D:/active/bis-fogo/data/field-campaign"
top_level_outpath <- "D:/active/bis-fogo/data/field-campaign"

# Use this for the Cape Verdian national projection as defined by
# SR-ORG:7391 at www.spatialreference.org and EPSG:4825 at
# www.epsg.io
proj_out <- paste0("+proj=lcc +lat_1=15 +lat_2=16.66666666666667 ",
                   "+lat_0=15.83333333333333 +lon_0=-24 +x_0=161587.83 ",
                   "+y_0=128511.202 +datum=WGS84 +units=m +no_defs")


#### DO NOT CHANGE ANYTHING BELOW THIS LINE EXCEPT YOU KNOW WHAT YOU DO ########
#### Merge vegetation and animal files #########################################
setwd(top_level_outpath)

veg_tec <- read.table("plots_vegetation_2014_tec.csv", 
                  header = FALSE, sep = ";", skip = 2, stringsAsFactors = FALSE)
veg_agr <- read.table("plots_vegetation_2014_agr.csv", 
                      header = FALSE, sep = ";", skip = 2, stringsAsFactors = FALSE)
veg_nat <- read.table("plots_vegetation_2014_nat.csv", 
                      header = FALSE, sep = ";", skip = 2, stringsAsFactors = FALSE)
anm <- read.table("plots_animals_2014.csv", header = TRUE, sep = ";", stringsAsFactors = FALSE)

# Set column names of vegetation data frames
colnames(veg_tec) <- sapply(veg_tec[2,], toupper)
colnames(veg_agr) <- sapply(seq(ncol(veg_agr[2,])), function(x){
  paste0(toupper(veg_agr[2,x]), "_", substr(veg_agr[3,x], 1, nchar(as.character(veg_agr[3,x]))-1))
})
colnames(veg_nat) <- sapply(seq(ncol(veg_nat[2,])), function(x){
  paste0(toupper(veg_nat[2,x]), "_", substr(veg_nat[3,x], 1, nchar(as.character(veg_nat[3,x]))-1))
})

# Clean and merge vegetation data sets
veg_tec <- veg_tec[-2,]
veg_agr <- veg_agr[-2,]
veg_nat <- veg_nat[-2,]

veg <- merge(veg_tec, veg_agr, by.x = "ID", by.y = "ID_")
veg <- veg[c(-3,-4),]
veg <- merge(veg, veg_nat, by.x = "ID", by.y = "ID_")
veg <- veg[c(-2,-3),]
veg$ID[1] <- "Info1"
veg$ID[2] <- "Info2"
veg$IDA[1] <- "Info1"
veg$IDA[2] <- "Info2"

write.table(veg, "plots_vegetation_2014_merged.csv", sep = ",", row.names = FALSE)

# Clean animal data set and merge with vegetation data set
anm$ID <- NULL
anm$IDA[1] <- "Info2"
anm <- anm[c(-52, -53),]

veg_anm <- merge(veg, anm, by = "IDA", all.x = TRUE)
write.table(veg_anm, "plots_veg_anm_2014.csv", sep = ",", row.names = FALSE)

#vegshape <- readOGR("plots_vegetation_2014.shp", layer = "polygon")
#anmshape <- readOGR("plots_vegetation_2014.shp", layer = "polygon")


