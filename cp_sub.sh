#!/bin/bash

set -e
# DEFAULT_DEST="/mnt/hdd/Anime"

# find $DEFAULT_DEST -type f \( -name "*.vi.*" -o -name "*.vie.*" \) | while read filename; do
# DIR="$(dirname "${filename}" | sed -e "s/^\.//")" ;
# DIR="$(realpath --relative-to="/mnt/hdd" "${DIR}")"
# # FILE="$(basename "${filename}")"

#   mkdir -p "/mnt/hdd/backup/AnimeSubtitles/$DIR"
#   cp "$filename" "/mnt/hdd/backup/AnimeSubtitles/$DIR/"
# done

# DEFAULT_DEST="/mnt/hdd/Movie"

# find $DEFAULT_DEST -type f \( -name "*.vi.*" -o -name "*.vie.*" \) | while read filename; do
# DIR="$(dirname "${filename}" | sed -e "s/^\.//")" ;
# DIR="$(realpath --relative-to="/mnt/hdd" "${DIR}")"
# # FILE="$(basename "${filename}")"

#   mkdir -p "/mnt/hdd/backup/AnimeSubtitles/$DIR"
#   cp "$filename" "/mnt/hdd/backup/AnimeSubtitles/$DIR/"
# done


DIR="$(dirname "$1")" ;
DIR="$(realpath --relative-to="/mnt/hdd" "${DIR}")"
mkdir -p "/mnt/hdd/backup/AnimeSubtitles/$DIR"
cp "$1" "/mnt/hdd/backup/AnimeSubtitles/$DIR/"
