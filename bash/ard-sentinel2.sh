#!/bin/bash

# PROG=`basename $0`;
BIN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# make sure script exits if any process exits unsuccessfully
set -e

# parse config file
IMAGE=$("$BIN"/read-config.sh "FORCE_IMAGE")
FILE_ARD_SENTINEL2_PARAM=$("$BIN"/read-config.sh "FILE_ARD_SENTINEL2_PARAM")
DIR_TEMP=$(sed -nr 's/^DIR_TEMP.*= *(.+)$/\1/p' "$FILE_ARD_SENTINEL2_PARAM")
USER_GROUP=$("$BIN"/read-usergroup-ids.sh)

# preprocess the S2 L1C to L2 ARD
docker run \
--rm \
-e FORCE_CREDENTIALS=/app/credentials \
-e BOTO_CONFIG=/app/credentials/.boto \
-v "$HOME:/app/credentials" \
-v /data:/data \
-v /mnt:/mnt \
-v "$HOME:$HOME" \
-v "$DIR_TEMP:$DIR_TEMP" \
-w "$PWD" \
-u "$USER_GROUP" \
"$IMAGE" \
force-level2 \
  "$FILE_ARD_SENTINEL2_PARAM"

exit 0
