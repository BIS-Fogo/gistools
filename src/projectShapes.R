#  Re-project ESRI-shape files to another coordinate system
#
#  Copyright (C) 2014 Hanna Meyer, Thomas Nauss
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
#  The script re-projects all ESRI-shape files in a given folder and all its
#  sub-folders. Since GIS filenames often include whitespaces or special 
#  characters (also they shouldn't), each data set is temporary renamend prior
#  to the projection and set back to its original filename afterwards.
#  To run the script, adjust the following variables (if no one else did it
#  for you):
#  inPath - full path to the top level input folder
#  topLevelOutPath - full path to the output folder
#  proj.out - proj4 string of the target projection (see web pages above)
#  
#  NOTE: DO NOT USE A TOP LEVEL OUTPUT PATH WHICH IS INSIDE THE TOP LEVEL INPUT
#        PATH

#### User setttings ############################################################
inPath <- "D:/active/bis-fogo/data/fogo_national_park/PG-PNF/Shapes"
topLevelOutPath <- "D:/active/bis-fogo/test"

# Use this for the Cape Verdian national projection as defined by
# SR-ORG:7391 at www.spatialreference.org and EPSG:4825 at
# www.epsg.io
proj.out <- paste0("+proj=lcc +lat_1=15 +lat_2=16.66666666666667 ",
                   "+lat_0=15.83333333333333 +lon_0=-24 +x_0=161587.83 ",
                   "+y_0=128511.202 +datum=WGS84 +units=m +no_defs")


#### DO NOT CHANGE ANYTHING BELOW THIS LINE EXCEPT YOU KNOW WHAT YOU DO ########
#### Reprojection of shape files ###############################################
error.message <- paste0("User-definded variable topLevelOutPath has same ",
                        "value as inPath. This could overwrite your original ",
                        "data set.")
if(grepl(inPath, topLevelOutPath)) stop(error.message)

Packages <- c("sp","raster","maptools",
              "plotKML","rgeos","dismo","maps","rgdal")
lapply(Packages, library, character.only = TRUE)

setwd(inPath)
inFolders <- list.dirs(path = ".",recursive = TRUE, full.names = FALSE)

for (folder in inFolders[2:length(inFolders)]){  
  outPath <- paste0(topLevelOutPath, "/", folder)
  dir.create (outPath, recursive = TRUE)
  setwd(paste0(inPath, "/", folder))
  shapelist <- list.files(pattern = glob2rx("*.shp"))
  
  for(shapeFile in shapelist){
    layer <- substr(shapeFile, 1, nchar(shapeFile)-4)
    prjFile <- paste0(substr(shapeFile, 1, nchar(shapeFile) - 3), "prj")
    shapeLayer <- try(readOGR(shapeFile, layer), silent = TRUE)
    if('try-error' %in% class(shapeLayer)) next
    prjInfo <- try(readChar(prjFile, nchars=50), silent = TRUE)
    if('try-error' %in% class(prjInfo)) next
    if(grepl("WGS_1984_Complex_UTM_Zone_26N", prjInfo)){
      proj.in <- paste0("+proj=utm +zone=26 +datum=WGS84 +units=m +no_defs ",
                        "+ellps=WGS84 +towgs84=0,0,0")
      proj4string(shapeLayer) <- CRS(proj.in)
    }
    if (!is.na(proj4string(shapeLayer))){
      shapeLayer <- spTransform(shapeLayer, CRS(proj.out))
      shapeLayer <- writeOGR(shapeLayer, outPath, layer, 
                             driver<-"ESRI Shapefile", overwrite_layer = TRUE)
      #change projection name
      prjNew <- try(readChar(paste0(outPath,"/",layer,".prj"), nchars=900), silent = TRUE)
      prjNew=gsub("Lambert_Conformal_Conic","Cabo Verde Cónica Secante de Lambert",prjNew)
      writeChar(prjNew,paste0(outPath,"/",layer,".prj"))
    }
  }
}