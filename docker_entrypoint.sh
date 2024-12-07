#!/bin/bash
set -e
# set from directory
INPUT_DIR=/input
# set to directory
OUTPUT_DIR=/output
# generate temporary directory
TIFF_DIR=$OUTPUT_DIR/tiff
# MAX_ZOOM
MAX_ZOOM=17
# MIN_ZOOM
MIN_ZOOM=5
# RUn gmldem2tif
cd /app/gmldem2tif
bundle exec ruby gmldem2tif.rb -v -n `nproc` $INPUT_DIR $TIFF_DIR
cd /output
# Create vrt file
gdalbuildvrt -a_srs EPSG:4326 -hidenodata all.vrt $TIFF_DIR/*.tif
# Create tif file
gdal_translate -co compress=lzw -co BIGTIFF=YES -of GTiff all.vrt all.tiff
# Calculate tif file
gdal_calc.py --co="COMPRESS=LZW" --co="BIGTIFF=YES" --type=Float32 -A all.tiff --outfile=all_calc.tiff --calc="A*(A>0)" --NoDataValue=0
# Run rio-rgbify
rio rgbify -b -10000 -i 0.1 --format png --max-z $MAX_ZOOM --min-z $MIN_ZOOM -j `nproc` all_calc.tiff mapbox.mbtiles
# Unarchive mbtiles
mb-util --image_format=png mapbox.mbtiles $OUTPUT_DIR/mapbox
# Run rio-termarium
rio terrarium --format png --max-z $MAX_ZOOM --min-z $MIN_ZOOM -j `nproc` all_calc.tiff terrarium.mbtiles
# Unarchive mbtiles
mb-util --image_format=png terrarium.mbtiles $OUTPUT_DIR/terrarium
# Create vrt file with nodata
gdalbuildvrt -a_srs EPSG:4326 -srcnodata 9999 all_with_nodata.vrt $TIFF_DIR/*.tif
# Create tif file with nodata
gdal_translate -co compress=lzw -co BIGTIFF=YES -of GTiff -a_nodata 9999 all_with_nodata.vrt all_with_nodata.tiff
# Run rio-gsidem
rio gsidem --format png --max-z $MAX_ZOOM --min-z $MIN_ZOOM -j `nproc` all_with_nodata.tiff gsidem.mbtiles
# Unarchive mbtiles
mb-util --image_format=png gsidem.mbtiles $OUTPUT_DIR/gsidem
