#!/bin/bash
# Extract subtitles from each MKV file in the given directory

# set -e

BASE_FOLDER="/mnt/hdd"
if [[ ! -f "$BASE_FOLDER/backup/AnimeSubtitles/last_extract_sub" ]]; then
	date +"00-%m-%d %H:%M:%S.%N +0000" >"$BASE_FOLDER/backup/AnimeSubtitles/last_extract_sub"
fi

TIME_STAMP="$(date +"%Y-%m-%d %H:%M:%S.%N +0000")"
touch --date "$(cat $BASE_FOLDER/backup/AnimeSubtitles/last_extract_sub)" -m "$BASE_FOLDER/backup/AnimeSubtitles/last_extract_sub"

SEARCH_DIRS=("$BASE_FOLDER/Anime" "$BASE_FOLDER/Movie")
for sub_folder in ${SEARCH_DIRS[@]}; do
	if [[ ! -d "$sub_folder" ]]; then
		continue
	fi
	# Get all the MKV files in this dir and its subdirs
	find "$sub_folder" -type f -name '*.mkv' | while read -r filename; do
		FILE_BASE_NAME=${filename%.*}
		if [[ -f "${FILE_BASE_NAME}.vie.sup" ]] || [[ -f "${FILE_BASE_NAME}.vi.sup" ]] || [[ -f "${FILE_BASE_NAME}.vie.ass" ]] || [[ -f "${FILE_BASE_NAME}.vi.ass" ]] || [[ -f "${FILE_BASE_NAME}.vi.srt" ]] || [[ -f "${FILE_BASE_NAME}.vie.srt" ]]; then
			continue
		fi
		# Find out which tracks contain the subtitles
		mkvmerge -J "$filename" | jq -c '.tracks[] | select(.type=="subtitles" and (.properties.language=="vie" or .properties.language=="und"))' | while read -r subline; do
			# Grep the number of the subtitle track
			tracknumber=$(echo "$subline" | jq -c ".id")
			language=$(echo "$subline" | jq -c ".properties.language")
			codec=$(echo "$subline" | jq -c ".codec")
			file_extension=""
			if [[ $codec == *"SubRip/SRT"* ]]; then
				file_extension="srt"
			elif [[ $codec == *"SubStationAlpha"* ]] || [[ $codec == *"AdvancedSub"* ]]; then
				file_extension="ass"
			elif [[ $codec == *"HDMV PGS"* ]]; then
				file_extension="sup"
			fi
			# Get base name for subtitle
			subtitlename=${FILE_BASE_NAME}

			if [[ -z $file_extension ]]; then
				echo "$filename" >>"$BASE_FOLDER/backup/AnimeSubtitles/unknown_sub_type.log"
				echo "$codec" >>"$BASE_FOLDER/backup/AnimeSubtitles/unknown_sub_type.log"
				continue
			fi
			# Extract the track to a .tmp file
			{
				mkvextract tracks "$filename" --redirect-output "$BASE_FOLDER/backup/AnimeSubtitles/extract_error.log" -q "$tracknumber":"$subtitlename.vie.$file_extension.bak" && mv "$subtitlename.vie.$file_extension.bak" "$subtitlename.vie.$file_extension"
			} || {
				rm "$subtitlename.vie.$file_extension.bak"
			}
		done
	done

done
echo "$TIME_STAMP" >"$BASE_FOLDER/backup/AnimeSubtitles/last_extract_sub"
