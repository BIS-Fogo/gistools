#  Visualize lava flow based on Landsat and Quickbird
#
#  Copyright (C) 2014 Thomas Nauss
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
#  Details:
#
rm(list = ls(all = T))

#### Define Working directory ##################################################
working_directory <- "active/bis-fogo/analysis/vulcano_2014/"

dsn <- switch(Sys.info()[["sysname"]], 
              "Linux" = "/media/permanent/",
              "Windows" = "D:/")
working_directory <- paste0(dsn, working_directory)
in_path <- paste0(working_directory,".")
qb_path <- ("D:/active/bis-fogo/data/remote-sensing/quickbird/")
out_path <- paste0(working_directory)
setwd(working_directory)
analysis_id = "vlc2014"
analysis_id <- paste0(analysis_id, "_")


#### Load required libraries ###################################################
library(raster)


#### Read data sets ############################################################
# bands <- list.files(path = ".", 
#                     pattern =  glob2rx("*.tif"),
#                     full.names = TRUE, recursive = TRUE)
# bands_relevant <- bands[c(2, 7, 8, 11, 4, 6)]
# landsat <- stack(bands_relevant)
# hist(landsat[[5]], maxpixels = 1143300, breaks = 1000, 
#      xlim = c(280,300), ylim = c(0,1000))
lava07 <- 
  readOGR(
    paste0(out_path, 
           "LC82100502014328LGN00_B7_mask/LC82100502014328LGN00_B7_mask.shp"),
          "LC82100502014328LGN00_B7_mask")
lava10 <- 
  readOGR(
    paste0(out_path, 
           "LC82100502014328LGN00_B10_K_mask/LC82100502014328LGN00_B10_K_mask.shp"),
    "LC82100502014328LGN00_B10_K_mask")

fnp <- readOGR(paste0(out_path, "NatureParkCenter.shp"), "NatureParkCenter")
fnp <- spTransform(fnp, CRS(projection(lava10)))

# qb <- stack(paste0(qb_path, "fg2.tif"))
# qp_crop <- crop(qb, extent(c(779837, 786768, 1651084, 1656879)))
# writeRaster(qb_crop, paste0(out_path, "fg2_croped.tif"))
qb <- stack(paste0(out_path, "fg2_croped.tif"))


#### Create map ################################################################
tiff(paste0(out_path, analysis_id, "landsat_lava_2014-11-24.tiff"),
     compression = "lzw", width = 2400, height = 1800, res = 300)
plotRGB(qb, axes = TRUE, maxpixels=5000000, 
        main = "Active lava flow on 11/24/2014 at 11:58 GMT derived from Landsat 8")
plot(lava07, add = TRUE, col = "orange")
plot(lava10, add = TRUE, col = "red")
plot(fnp, add = TRUE, col = "green", cex = 2)
legend("topright", 
       legend = c("Lava flow identified using Band 07", 
                  "Lava flow identified using Band 10",
                  "Headquator of fogo natural park"), 
       fill = c("orange", "red", "white"),  border = "white",
       pch = c(NA, NA, 3), col = c("white", "white", "green"),
       cex = 0.5)
dev.off()
