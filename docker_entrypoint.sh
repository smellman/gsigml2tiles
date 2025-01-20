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
# skip gmldem2tif if all.tiff exist
if [ -f "$OUTPUT_DIR/all.tiff" ]; then
    echo "all.tiff exists. Skipping gmldem2tif.rb processing."
else
    # RUn gmldem2tif
    cd /app/gmldem2tif
    bundle exec ruby gmldem2tif.rb -v -n `nproc` $INPUT_DIR $TIFF_DIR
fi
cd $OUTPUT_DIR
# Skip create tiff file if all_calc.tiff exist
if [ -f "$OUTPUT_DIR/all_calc.tiff" ]; then
    echo "all_calc.tiff exists. Skipping geotiff processing."
else
    # Create vrt file
    gdalbuildvrt -a_srs EPSG:4326 -srcnodata "-9999" all.vrt $TIFF_DIR/*.tif
    # Create tif file
    gdal_translate -co compress=lzw -co BIGTIFF=YES -a_nodata "-9999" -of GTiff all.vrt all.tiff
    # Calculate tif file
    gdal_calc.py --co="COMPRESS=LZW" --co="BIGTIFF=YES" --type=Float32 -A all.tiff --outfile=all_calc.tiff --calc="0*(A<=-9998) + A*(A>-9998)" --NoDataValue=-9999
fi
# Skip rio-rgbify if mapbox.mbtiles exist
if [ -f "$OUTPUT_DIR/mapbox.mbtiles" ]; then
    echo "mapbox.mbtiles exists. Skipping rio-rgbify processing."
else
    # Run rio-rgbify
    rio rgbify -b -10000 -i 0.1 --format png --max-z $MAX_ZOOM --min-z $MIN_ZOOM -j `nproc` all_calc.tiff mapbox.mbtiles
    # Unarchive mbtiles
    mb-util --image_format=png mapbox.mbtiles $OUTPUT_DIR/mapbox
fi
# Skip rio-terrarium if terrarium.mbtiles exist
if [ -f "$OUTPUT_DIR/terrarium.mbtiles" ]; then
    echo "terrarium.mbtiles exists. Skipping rio-terrarium processing."
else
    # Run rio-terrarium
    rio terrarium --format png --max-z $MAX_ZOOM --min-z $MIN_ZOOM -j `nproc` all_calc.tiff terrarium.mbtiles
    # Unarchive mbtiles
    mb-util --image_format=png terrarium.mbtiles $OUTPUT_DIR/terrarium
fi
# Skip create nodata tiff file if all_with_nodata.tiff exist
if [ -f "$OUTPUT_DIR/all_with_nodata.tiff" ]; then
    echo "all_with_nodata.tiff exists. Skipping geotiff processing."
else
    # Create vrt file with nodata
    gdalbuildvrt -a_srs EPSG:4326 -srcnodata "-9999" all_with_nodata.vrt $TIFF_DIR/*.tif
    # Create tif file with nodata
    gdal_translate -co compress=lzw -co BIGTIFF=YES -of GTiff -a_nodata "-9999" all_with_nodata.vrt all_with_nodata.tiff
fi
# Skip create gsidem if gsidem directory exist
if [ -d "$OUTPUT_DIR/gsidem" ]; then
    echo "gsidem directory exists. Skipping gdal2NPTiles processing."
else
    python3 /usr/local/bin/gdal2NPtiles.py --numerical --processes=$(nproc) --xyz -a "-9999" -z 5-17 all_with_nodata.tiff $OUTPUT_DIR/gsidem
fi
