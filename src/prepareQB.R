#  Quick and dirty prediction of plant species richness using Landsat 8
#
#  Copyright (C) 2014 Hanna Meyer, Thomas Nauss, Roland Brandl
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
#  The script reads Landsat 8 and species richness data and applies machine
#  learning models to predict the species richness based on the Landsat 
#  spectral information.

#### User setttings ############################################################
tlpath <- "D:/active/bis-fogo/analysis/"


#### General setttings #########################################################
packages <- c("raster", "rgdal", "caret", "corrplot", "latticeExtra")
lapply(packages, library, character.only = TRUE)

setwd(tlpath)
datapath <- paste0(tlpath, "data")
figurepath <- paste0(tlpath, "figures")


#### Merge quickbird data sets for the caldera region ##########################
# rasterList <- c(list.files("D:/active/bis-fogo/data/fogo_national_park/quickbird",
#                          pattern = "*.tif", full.names = TRUE),
#                 list.files("C:/Users/tnauss/Desktop/quickbird2",
#                            pattern = "*.tif", full.names = TRUE))
# 
# area <- as(extent(778626.1, 787071.6, 1650520, 1650520), "SpatialPolygons")
# qb <- lapply(rasterList, function(x){
#   band <- stack(x)
#   band.crop <- crop(band, area)
# })
# qb.merge <- do.call(merge, qb)
# writeRaster(qb.merge, "qbmerge.tif", format = "GTiff")

#### Load species richness and Landsat data sets ###############################
load("richness.sav")
proj <- paste0("+proj=utm +zone=26 +datum=WGS84 +units=m +no_defs ",
               "+ellps=WGS84 +towgs84=0,0,0")
coordinates(data.richness) <- ~E + N
projection(data.richness) <- proj

landsat <- stack("fogo.tif")
# plot(landsat)
dlr <- data.frame(extract(landsat, data.richness), 
                  data.richness)
dlr <- dlr[,c(-12,-13)]

# Reduce bands based on high auto-correlation 
dlr.cor <- as.matrix(cor(dlr[,-14]))
corrplot(dlr.cor)
dlr.cor.rm <- findCorrelation(dlr.cor, verbose = TRUE)
dlr.clean <- dlr[,-(dlr.cor.rm+1)]
dlr.clean$rich <- as.factor(dlr.clean$rich)
dlr.clean <- rbind(dlr.clean, dlr.clean)

method <- "rf"
pdf("predict_SR_Landsat.pdf")
predPerformance <- data.frame(PRED = factor(), VALD = factor())
importance <- data.frame(band = factor(), MeanDecreaseGini = numeric())
for(x in 1:3){
  trainIndex <- createDataPartition(dlr.clean[,ncol(dlr.clean)], 
                                    p = 0.7, list = FALSE)
  df.train <- dlr.clean[trainIndex,]
  df.test <- dlr.clean[-trainIndex,]
  
  model.train <- train(df.train[,-ncol(df.train)], df.train[,ncol(df.train)], 
                       method = method, tuneLength = 3)
  plot(model.train)
  if(method == "rf") varImpPlot(model.train$finalModel)
  model.test <- predict(model.train, df.test[,-ncol(df.train)])
  tmp <- data.frame(PRED = model.test,
                    VALD = df.test[,ncol(df.train)])
  predPerformance <- data.frame(rbind(predPerformance, tmp))
  tmp <- importance(model.train$finalModel)
  tmp <- data.frame(band = rownames(tmp), 
                    MeanDecreaseGini = tmp)
  importance <- data.frame(rbind(importance, tmp))
}
dev.off()
confusionMatrix(table(predPerformance))

sort <- aggregate(importance$MeanDecreaseGini, by = list(importance$band), FUN = mean)
sort <- sort[with(sort, order(x)), ][1]
importance$band <- factor(importance$band, levels=as.character(sort[,1]))
bwplot(band~MeanDecreaseGini, data = importance)
