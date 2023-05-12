#! /bin/bash

# 使用 ghostscript对文件中的pdf进行压缩

# set -x

if [ ! "$(command -v gs)" ]; then
    echo -e "没有安装 ghostscript，安装：\033[34m apt install ghostscript \033[0m"
    exit 1
fi

SRC=$1

for FILE in $(find $SRC -type f -regex ".*\.pdf$"); do
	DEST_ORIG=$(echo $FILE | sed 's%/[^/]*$%/%')
	filename=$(basename $FILE)
	extension=${filename##*.}
	filename=${filename%.*}
	Size_SRC=$(du -h "$FILE" | cut -f1)
	Start_Compression=$(date +"%H:%M:%S")
	echo -e "start compress pdf \033[34m$FILE\033[0m"
	MIN_PDF="$DEST_ORIG$filename.GHS.pdf"

	# 使用 ghostscript 压缩pdf
	gs  -sDEVICE=pdfwrite -dDetectDuplicateImages=true -dColorImageResolution=150 -dDownsampleColorImages=true -dJPEGQ=95 -dNOPAUSE -dQUIET -dBATCH -dPDFSETTINGS=/${3:-"ebook"} -dCompatibilityLevel=1.4 -sOutputFile="$MIN_PDF" "$FILE"

	compressed_pdf_size=$(du -s "$MIN_PDF" | cut -f1)
  	original_pdf_size=$(du -s "$FILE" | cut -f1)

	if [ $compressed_pdf_size -lt $original_pdf_size ]; then
		rm "$FILE"
		mv "$MIN_PDF" "$FILE"
	else
		rm "$MIN_PDF"
	fi
	
	End_Compression=$(date +"%H:%M:%S")
	StartDate=$(date -u -d "$Start_Compression" +"%s")
	FinalDate=$(date -u -d "$End_Compression" +"%s")
	Compression_Time=$(date -u -d "0 $FinalDate sec - $StartDate sec" +"%H:%M:%S")
	Size_HB=$(du -h "$FILE" | cut -f1)

	echo -e "End compressing \033[34m$FILE\033[0m fileSize: \033[33m$Size_SRC >> $Size_HB\033[0m in time: \033[32m$Compression_Time\033[0m "
done
