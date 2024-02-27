#!/bin/bash

set -e

BASE_FOLDER="/mnt/hdd"
if [[ ! -f "$BASE_FOLDER/backup/AnimeSubtitles/last_scan" ]]; then
	date +"00-%m-%d %H:%M:%S.%N +0000" >"$BASE_FOLDER/backup/AnimeSubtitles/last_scan"
fi

TIME_STAMP="$(date +"%Y-%m-%d %H:%M:%S.%N +0000")"
touch --date "$(cat $BASE_FOLDER/backup/AnimeSubtitles/last_scan)" -m "$BASE_FOLDER/backup/AnimeSubtitles/last_scan"

# Convert srt to ass subtitles
# $1 sub absolute path, $2 save folder
convertSrtToAss() {
	SUB_CHARSET="$(uchardet "$1")"
	SUB_ORIGIN_DIR="$(dirname "$1")"
	FILE_BASE_NAME="$(echo "$1" | basename "$(sed -E 's/.(vi|vie).(srt|ass|sup)$//')")"
	SAVE_TO_FILE="$2/$FILE_BASE_NAME.vie.ass"
	ffmpeg -y -nostdin -loglevel panic -sub_charenc "$SUB_CHARSET" -i "$1" "$SAVE_TO_FILE"

	mv "$SAVE_TO_FILE" "$SAVE_TO_FILE.bak"
	# DEMENSION=$(find "$SUB_ORIGIN_DIR" -type f \( -iname "$FILE_BASE_NAME.mkv" -o -iname "$FILE_BASE_NAME.mp4" \) | while read -r videofile; do
	# 	ffprobe -v error -select_streams v -show_entries stream=width,height -of csv=p=0:s=x "$videofile"
	# done)

	# if [[ $DEMENSION != *x* ]]; then
	DEMENSION="1920x1080"
	# fi
	WIDTH="$(echo "$DEMENSION" | cut -d "x" -f 1)"
	HEIGHT="$(echo "$DEMENSION" | cut -d "x" -f 2)"

	while read -r TEMPLATE_LINE; do

		case "$TEMPLATE_LINE" in

		"PlayResX"*)
			TEMPLATE_LINE="PlayResX: $WIDTH"
			;;

		"PlayResY"*)
			TEMPLATE_LINE="PlayResY: $HEIGHT"
			;;
		esac
		echo "$TEMPLATE_LINE" >>"$SAVE_TO_FILE"
	done <"$BASE_FOLDER/backup/AnimeSubtitles/ass_template.ass"

	# Concat with sub dialogs
	tail -n+12 "$SAVE_TO_FILE.bak" >>"$SAVE_TO_FILE"
	dos2unix -q "$SAVE_TO_FILE"
	# Remove temp file
	if [[ -f "$SAVE_TO_FILE.bak" ]]; then
		rm "$SAVE_TO_FILE.bak"
	fi
}

# fixDemension() {
# 	SUB_ORIGIN_DIR="$(dirname "$1")"
# 	FILE_BASE_NAME="$(echo "$1" | basename "$(sed -E 's/.(vi|vie).(srt|ass)$//')")"
# 	SAVE_TO_FILE="$2/$FILE_BASE_NAME.vie.ass"
# 	mv "$SAVE_TO_FILE" "$SAVE_TO_FILE.bak"
# 	DEMENSION=$(find "$SUB_ORIGIN_DIR" -type f \( -iname "$FILE_BASE_NAME.mkv" -o -iname "$FILE_BASE_NAME.mp4" \) | while read -r videofile; do
# 		ffprobe -v error -select_streams v -show_entries stream=width,height -of csv=p=0:s=x "$videofile"
# 	done)

# 	if [[ $DEMENSION != *x* ]]; then
# 		DEMENSION="1920x1080"
# 	fi
# 	WIDTH="$(echo "$DEMENSION" | cut -d "x" -f 1)"
# 	HEIGHT="$(echo "$DEMENSION" | cut -d "x" -f 2)"

# 	UPDATED_RES_X=false
# 	UPDATED_RES_Y=false
# 	while read -r TEMPLATE_LINE; do
# 		case "$TEMPLATE_LINE" in

# 		"PlayResX"*)
# 			TEMPLATE_LINE="PlayResX: $WIDTH"
# 			UPDATED_RES_X=true
# 			;;

# 		"PlayResY"*)
# 			TEMPLATE_LINE="PlayResY: $HEIGHT"
# 			UPDATED_RES_Y=true
# 			;;
# 		esac
# 		echo "$TEMPLATE_LINE" >>"$SAVE_TO_FILE"
# 	done <"$SAVE_TO_FILE.bak"

# 	# Concat with sub dialogs
# 	tail -n+12 "$SAVE_TO_FILE.bak" >>"$SAVE_TO_FILE"
# 	dos2unix -q "$SAVE_TO_FILE"
# 	# Remove temp file
# 	if [[ -f "$SAVE_TO_FILE.bak" ]]; then
# 		rm "$SAVE_TO_FILE.bak"
# 	fi
# }
pushd "$BASE_FOLDER/backup/AnimeSubtitles/" || exit
git lfs fetch --all
git lfs checkout
git lfs pull
SEARCH_DIRS=("$BASE_FOLDER/Anime" "$BASE_FOLDER/Movie")

for sub_folder in ${SEARCH_DIRS[@]}; do
	if [[ ! -d "$sub_folder" ]]; then
		continue
	fi
	find "$sub_folder" -newer "$BASE_FOLDER/backup/AnimeSubtitles/last_scan" -type f \( -iname "*.srt" -o -iname "*.ass" -o -name "*.sup" \) | while read -r filename; do
		DIR_ABSOLUTE="$(dirname "$filename")"
		DIR="$(realpath --relative-to="$BASE_FOLDER" "$DIR_ABSOLUTE")"
		FILE_BASE_NAME="$(echo "$filename" | basename "$(sed -E 's/.(vi|vie).(srt|ass|sup)$//')")"
		mkdir -p "$BASE_FOLDER/backup/AnimeSubtitles/$DIR"
		mkdir -p "/mnt/hdd2/backup/AnimeSubtitles/$DIR"
		if [[ $filename == *.vi.srt ]] || [[ $filename == *.vie.srt ]]; then
			convertSrtToAss "$filename" "$BASE_FOLDER/backup/AnimeSubtitles/$DIR"
			cp "$BASE_FOLDER/backup/AnimeSubtitles/$DIR/$FILE_BASE_NAME.vie.ass" "$DIR_ABSOLUTE/$FILE_BASE_NAME.vie.ass"
			cp "$BASE_FOLDER/backup/AnimeSubtitles/$DIR/$FILE_BASE_NAME.vie.ass" "/mnt/hdd2/backup/AnimeSubtitles/$DIR/"
		fi
		cp "$filename" "$BASE_FOLDER/backup/AnimeSubtitles/$DIR/"
		cp "$filename" "/mnt/hdd2/backup/AnimeSubtitles/$DIR/"
	done
done

echo "$TIME_STAMP" >"$BASE_FOLDER/backup/AnimeSubtitles/last_scan"
git add -A
git commit -m "auto push sub $TIME_STAMP"
git lfs migrate import --everything --above=50MB --yes
git push origin
curl -H "Content-Type: application/json" -X POST "http://localhost:8096/Library/Refresh?api_key=$JELLYFIN_API_KEY"
