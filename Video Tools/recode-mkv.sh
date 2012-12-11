#!/bin/bash
#
# This transcode settings works for my Samsung Smart TV and also include
# the spanish and english SRT inside the MKV, AAC is used for audio
#
SOURCE=$1
BASENAME=$(basename "${SOURCE}" .mkv) 
DIRNAME=$(echo ${SOURCE} | awk -F/ '{print $(NF-3) "/" $(NF-2) "/" $(NF-1) }')
SRTS=$(echo $SOURCE | sed -e 's/\.mkv//')
OUTPUTDIR="/Volumes/Ext Disk 1/New/${DIRNAME}"
OUTPUT=${OUTPUTDIR}/${BASENAME}.mkv


if [ ! -e  "$SRTS.es.srt" ] || [ ! -e "$SRTS.en.srt" ]; then
   echo -e "\033[41m${SOURCE} Missing SRTs\033[0m"
   echo "${SOURCE} Missing SRTs" >> /tmp/convert-error.log
   exit 1
fi

if [ -e "${OUTPUT}" ] ; then 
   echo -e "\033[42m${SOURCE} already encoded\033[0m"
   exit 2
fi

if [ ! -e "${OUTPUTDIR}" ] ; then
  mkdir -p "${OUTPUTDIR}"
fi

/Volumes/HandBrake-0.9.8-MacOSX.6_CLI_x86_64/HandBrakeCLI \
	-i "$SOURCE" \
	-o "$OUTPUT" \
	-e x264 \
	--x264-tune film \
	-q 20 \
	--vfr \
	-a 1 \
	-E ca_aac \
	--ab 224 \
	--srt-file "$SRTS.es.srt","$SRTS.en.srt" \
	--srt-lang spa,eng \
	--stric	t-anamorphic \
	-w 1280 \
	-l 720 \
	-x ref=1:weightp=1:subq=2:rc-lookahead=10:trellis=0:8x8dct=0 

if [ $? -eq 0 ] ; then
   echo -e "\033[42m${OUTPUT} encoded OK\033[0m"
else
   echo -e "\033[41m${SOURCE} encoded with Errors\033[0m"
fi
