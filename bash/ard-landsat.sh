#!/bin/bash

# PROG=`basename $0`;
BIN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# make sure script exits if any process exits unsuccessfully
set -e

# parse config file
IMAGE=$("$BIN"/read-config.sh "FORCE_IMAGE")
FILE_ARD_LANDSAT_OLI_PARAM=$("$BIN"/read-config.sh "FILE_ARD_LANDSAT_OLI_PARAM")
FILE_ARD_LANDSAT_TM_PARAM=$("$BIN"/read-config.sh "FILE_ARD_LANDSAT_TM_PARAM")
FILE_LANDSAT_QUEUE=$("$BIN"/read-config.sh "FILE_LANDSAT_QUEUE")
USER_GROUP=$("$BIN"/read-usergroup-ids.sh)

# renamed queue
FILE_LANDSAT_QUEUE_TM=${FILE_LANDSAT_QUEUE%%.*}"_TM.txt"
FILE_LANDSAT_QUEUE_OLI=${FILE_LANDSAT_QUEUE%%.*}"_OLI.txt"

# parse temp directories
DIR_TEMP_LANDSAT_TM=$(sed -nr 's/^DIR_TEMP.*= *(.+)$/\1/p' "$FILE_ARD_LANDSAT_TM_PARAM")
DIR_TEMP_LANDSAT_OLI=$(sed -nr 's/^DIR_TEMP.*= *(.+)$/\1/p' "$FILE_ARD_LANDSAT_OLI_PARAM")

# split queue
set +e
grep "LE07_\|LT05_\|LT04_"  "$FILE_LANDSAT_QUEUE" > "$FILE_LANDSAT_QUEUE_TM"
grep "LC08_\|LC09_"  "$FILE_LANDSAT_QUEUE" > "$FILE_LANDSAT_QUEUE_OLI"
set -e

# count queue
NUM_TM=$(echo "$FILE_LANDSAT_QUEUE_TM" | wc -w)
NUM_OLI=$(echo "$FILE_LANDSAT_QUEUE_OLI" | wc -w)

# preprocess Landsat TM/ETM L1TP to L2 ARD
if [ "$NUM_TM" -gt 0 ]; then
docker run \
  --rm \
  -e FORCE_CREDENTIALS=/app/credentials \
  -e BOTO_CONFIG=/app/credentials/.boto \
  -v "$HOME":/app/credentials \
  -v /data:/data \
  -v /mnt:/mnt \
  -v "$DIR_TEMP_LANDSAT_TM:$DIR_TEMP_LANDSAT_TM" \
  -v "$HOME:$HOME" \
  -w "$PWD" \
  -u "$USER_GROUP" \
  "$IMAGE" \
  force-level2 \
    "$FILE_ARD_LANDSAT_TM_PARAM"
fi

# preprocess Landsat OLI L1TP to L2 ARD
if [ "$NUM_OLI" -gt 0 ]; then
  docker run \
  --rm \
  -e FORCE_CREDENTIALS=/app/credentials \
  -e BOTO_CONFIG=/app/credentials/.boto \
  -v "$HOME:/app/credentials" \
  -v /data:/data \
  -v /mnt:/mnt \
  -v "$DIR_TEMP_LANDSAT_OLI:$DIR_TEMP_LANDSAT_OLI" \
  -v "$HOME:$HOME" \
  -w "$PWD" \
  -u "$USER_GROUP" \
  "$IMAGE" \
  force-level2 \
    "$FILE_ARD_LANDSAT_OLI_PARAM"
fi

rm "$FILE_LANDSAT_QUEUE_TM"
rm "$FILE_LANDSAT_QUEUE_OLI"

exit 0
