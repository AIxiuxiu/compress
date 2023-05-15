#!/bin/bash

# 查找目录及子目录的图片文件(jpg,gif,png)，将大于某值的图片进行压缩处理
# 需要安装的命令工具

# apt install imagemagick
# apt install optipng
# apt install pngquant
# apt install jq

# 使用方式 bash compress.sh 压缩文件目录
# 记录日志 bash compress.sh 压缩文件目录 2>&1 | tee compress.log

# 用例
# bash compress.sh 'data/user/' 2>&1 | tee compress.log

# 调试命令
# set -x

# folderPath='/home/fdipzone/photo'  # 图片目录路径
folderPath=$1

# ----- imagemagick压缩设置 ----- #
imagemagickMaxSize=200k # 图片尺寸允许值
imagemagickQuality=80   # 图片质量
# resize="1920x1080>" #图片缩放设置
imagemagickResize="1920>" #图片缩放设置

#----- optipng 压缩设置 ----- #
optipngMaxSize=500k # 图片尺寸允许值

#----- pngquant 压缩设置 ----- #
pngquantMaxSize=200k  # 图片尺寸允许值
pngquantQuality=70-90 # 图片质量

#----- tinypng 压缩设置 ----- #
tinypngMaxSize=1M # 图片尺寸允许值

# tinypng的api key，每月500张免费图片
apiKeys=(
  "-QGvZ7H-4RFzjizRMsNf-rVVI_UTnmYK"
  "Zkf1LHXMWyyGcpUhsgH8bjET9j5oSw7S"
  "DC7Fxhf-iEw40XfDmAb3KrWRnEPfBEDN"
  "qJ2q_PJPcwPNkh-67iyBFLjja08hTaF6"
  "zZBeZRbbiuqn0k2H8Cl-3l66lPWCZ6VB"
  "BoOoA1UulwN_4-O_MN4UyN3U9YAm1ZUC"
  "bNQajkm4E5swM-T3eYUr9l_Hkpmg2SWM"
  "92eMC5fvjMhqyn3rnFhvnV7HH4QyQAR4"
  "T7V6Hoqj43O9mmot0wBB1Ic6A-XyTK0g"
  "ofXiw_AinfTA3XvK6TQ8gemLp32UqeGf"
  "HqeEITFeyKmkRME0tC3jaQBHmkSZuzUV"
  "8GLzzhNJPzruTOVysu9yD39kh-J0QGlH"
  "B1lQ91DKGnwyN6ZpM359JcSzkTYW8Xqg"
  "wkzVlBc96vtmQQsk7RQc5hff812spZvK"
)
key_index=0

#----- ghostscript 压缩设置 ----- #
pdfMaxSize=1M # pdf尺寸允许值

# 开始压缩处理
# Param $folderPath 图片目录
function compress() {
  folderPath=$1
  if [ -d "$folderPath" ]; then

    echo ""
    # imagemagick压缩，主要是限制最大宽度
    convertCompress "$folderPath"

    echo ""
    # optipng无损压缩png
    optipngCompress "$folderPath"

    echo ""
    # pngquant压缩png
    pngquantCompress "$folderPath"

    echo ""
    # tinypng 只压缩较大以上图片，压缩比高但请求慢
    tinypngCompress "$folderPath"

    echo ""
    # ghostscript 压缩pdf
    ghostscriptCompress "$folderPath"
  else
    echo -e "\033[31m $folderPath not exists \033[0m"
  fi
}

# convert压缩，主要是限制最大宽度，压缩png效果一般
function convertCompress() {

  folderPath="$1"
  fileNum=$(find "$folderPath" \( -name "*.jpg" -or -name "*.JPG" -or -name "*.jpeg" -or -name "*.png" -or -name "*.PNG" \) -type f -size +"$imagemagickMaxSize" | wc -l)
  echo -e "\033[35mimagemagick\033[0m start compress \033[31m$fileNum\033[0m images"

  for file in $(find "$folderPath" \( -name "*.jpg" -or -name "*.JPG" -or -name "*.jpeg" -or -name "*.png" -or -name "*.PNG" \) -type f -size +"$imagemagickMaxSize"); do

    imageSize=$(identify -format "%wx%h" "$file")
    fileSize=$(du -h "$file" | cut -f1)

    # 调用imagemagick resize图片
    $(convert -resize "$imagemagickResize" "$file" -strip -quality "$imagemagickQuality" "$file")

    nowImageSize=$(identify -format "%wx%h" "$file")
    nowFileSize=$(du -h "$file" | cut -f1)

    echo -e "convert \033[34m"$file"\033[0m imageSize: \033[33m"$imageSize" >> "$nowImageSize"\033[0m fileSize: \033[32m"$fileSize" >> "$nowFileSize"\033[0m"
  done

  runTme
  echo -e "\033[35mimagemagick\033[0m compress \033[32m$fileNum\033[0m images time: \033[31m"$runtime"\033[0m"
}

# optipng压缩png，无损压缩
function optipngCompress() {

  folderPath="$1"
  fileNum=$(find "$folderPath" \( -name "*.png" -or -name "*.PNG" \) -type f -size +"$optipngMaxSize" | wc -l)
  echo -e "\033[35moptipng\033[0m start compress \033[31m$fileNum\033[0m images"

  for file in $(find "$folderPath" \( -name "*.png" -or -name "*.PNG" \) -type f -size +"$optipngMaxSize"); do

    fileSize=$(du -h "$file" | cut -f1)

    # 调用optipng压缩png， -quiet静默模式运行
    $(optipng "$file" -fix -quiet "$file")

    nowFileSize=$(du -h "$file" | cut -f1)

    echo -e "optipng \033[34m"$file"\033[0m fileSize: \033[32m"$fileSize" >> "$nowFileSize" \033[0m"
  done

  runTme
  echo -e "\033[35moptipng\033[0m compress \033[31m$fileNum\033[0m images time: \033[31m"$runtime"\033[0m"
}

# pngquant压缩png，将png图像转换为更高效的8位png格式
function pngquantCompress() {

  folderPath="$1"
  fileNum=$(find "$folderPath" \( -name "*.png" -or -name "*.PNG" \) -type f -size +"$pngquantMaxSize" | wc -l)
  echo -e "\033[35mpngquant\033[0m start compress \033[31m$fileNum\033[0m images"

  for file in $(find "$folderPath" \( -name "*.png" -or -name "*.PNG" \) -type f -size +"$pngquantMaxSize"); do
    fileSize=$(du -h "$file" | cut -f1)

    # 调用pngquant压缩png
    # $(pngquant "$file" --ext .png  --skip-if-larger --quality 60-80 --verbose --force -- "$file")
    $(pngquant "$file" --ext .png --quality "$pngquantQuality" --force -- "$file")

    nowFileSize=$(du -h "$file" | cut -f1)

    echo -e "pngquant \033[34m"$file"\033[0m fileSize: \033[32m"$fileSize" >> "$nowFileSize" \033[0m"
  done

  runTme
  echo -e "\033[35mpngquant\033[0m compress \033[31m$fileNum\033[0m images time: \033[31m"$runtime"\033[0m"
}

# tinypng在线压缩，解决压缩后仍大于1M的图片
function tinypngCompress() {
  folderPath="$1"
  fileNum=$(find "$folderPath" \( -name "*.jpg" -or -name "*.JPG" -or -name "*.jpeg" -or -name "*.png" -or -name "*.PNG" \) -type f -size +"$tinypngMaxSize" | wc -l)
  echo -e "\033[35mtinypng\033[0m start compress \033[31m$fileNum\033[0m images"

  for file in $(find "$folderPath" \( -name "*.jpg" -or -name "*.JPG" -or -name "*.jpeg" -or -name "*.png" -or -name "*.PNG" \) -type f -size +"$tinypngMaxSize"); do
    tinypngValidate
    echo -e "tinypng current use key: \033[34m${apiKeys[key_index]}\033[34m"
    tinypngUplaod "$file"
  done

  runTme
  echo -e "\033[35mtinypng\033[0m compress \033[31m$fileNum\033[0m images time: \033[31m"$runtime"\033[0m"
}

function tinypngUplaod() {
  file="$1"
  echo -e "Uploading \033[34m$file\033[0m to tinypng"
  json=$(curl -sS --user api:${apiKeys[key_index]} --data-binary @"$file" https://api.tinypng.com/shrink)

  # 是否失败
  error=$(jq -n "$json.error")
  if [[ x$error != x"null" ]]; then
    echo -e "\033[31mtinypng error msg:$error \033[0m"
    old_index=$key_index
    tinypngValidate
    if [ $old_index -ne $key_index ]; then
      echo -e "tinypng current use key: \033[34m${apiKeys[key_index]}\033[34m"
      tinypngUplaod "$file"
    fi
  else
    url=$(jq -n "$json.output.url" | sed -e 's/^"//' -e 's/"$//')
    tinypngDownload "$url"
  fi
}

function tinypngValidate() {
  http_status="$(curl -o /dev/null -x '' -I -L -s -w '%{http_code}' --user api:${apiKeys[key_index]} https://api.tinypng.com/shrink)"
  if [ $http_status -eq 401 ] || [ $http_status -eq 429 ]; then
    echo -e "\033[31m ${apiKeys[key_index]} is use limit \033[0m"
    key_index=$(expr $key_index + 1)
    length=${#apiKeys[@]}
    if [[ $key_index -ge $length ]]; then
      echo -e "\033[31mno useful key to use \033[0m"
      exit 0
    else
      tinypngValidate
    fi
  fi
}

# 下载图片
function tinypngDownload() {
  url="$1"
  #如果url不为空下载
  if [ -z "$url" ] || [ x$url = x"null" ]; then
    echo -e "\033[31m $file tinypng compress error \033[0m"
  else
    echo -e "Download \033[34m$url\033[0m to \033[34m$file\033[0m fileSize: \033[32m$(jq -n "$json.input.size") >> $(jq -n "$json.output.size") \033[0m ratio: \033[33m$(jq -n "$json.output.ratio") \033[0m"
    curl -sS $url >"$file"
  fi
}

# ghostscript压缩pdf
function ghostscriptCompress() {

  folderPath="$1"
  fileNum=$(find "$folderPath" -type f -regex ".*\.pdf$" -size +"$pdfMaxSize" | wc -l)
  echo -e "\033[35mghostscript\033[0m start compress \033[31m$fileNum\033[0m pdf"

  for FILE in $(find $folderPath -type f -regex ".*\.pdf$" -size +"$pdfMaxSize"); do
    DEST_ORIG=$(echo $FILE | sed 's%/[^/]*$%/%')
    filename=$(basename $FILE)
    filename=${filename%.*}
    Size_SRC=$(du -h "$FILE" | cut -f1)
    echo -e "start compress pdf \033[34m$FILE\033[0m"
    MIN_PDF="$DEST_ORIG$filename.GHS.pdf"

    # 使用 ghostscript 压缩pdf
    gs -sDEVICE=pdfwrite -dDetectDuplicateImages=true -dColorImageResolution=150 -dDownsampleColorImages=true -dJPEGQ=95 -dNOPAUSE -dQUIET -dBATCH -dPDFSETTINGS=/${3:-"ebook"} -dCompatibilityLevel=1.4 -sOutputFile="$MIN_PDF" "$FILE"

    compressed_pdf_size=$(du -s "$MIN_PDF" | cut -f1)
    original_pdf_size=$(du -s "$FILE" | cut -f1)

    if [ $compressed_pdf_size -lt $original_pdf_size ]; then
      rm "$FILE"
      mv "$MIN_PDF" "$FILE"
    else
      rm "$MIN_PDF"
    fi

    Size_HB=$(du -h "$FILE" | cut -f1)

    echo -e "End compressing \033[34m$FILE\033[0m fileSize: \033[33m$Size_SRC >> $Size_HB\033[0m "
  done

  runTme
  echo -e "\033[35mghostscript\033[0m compress \033[31m$fileNum\033[0m pdf time: \033[31m"$runtime"\033[0m"
}

# 获取运行时间
starttime=$(date +'%Y-%m-%d %H:%M:%S')
runtime=''
function runTme() {
  endtime=$(date +'%Y-%m-%d %H:%M:%S')
  start_seconds=$(date --date="$starttime" +%s)
  end_seconds=$(date --date="$endtime" +%s)
  seconds=$((end_seconds - start_seconds))
  hour=3600
  min=60
  # seconds_format=$(date -d@"${seconds}" -u +%Mmin%Ss) # 格式化时间显示
  # runtime=${seconds_format#"00min"}            # 去掉0分钟情况前缀
  if [ $seconds -gt $hour ]; then
    runtime="$(($seconds / $hour))时$(($seconds % $hour / $min))分$(($seconds % $hour % $min))秒"
  elif [ $seconds -gt $min ]; then
    runtime="$(($seconds / $min))分$(($seconds % $min))秒"
  else
    runtime="$(($seconds))秒"
  fi
}

# 判断工具是否安装
function checkTool() {
  check=""
  if [ ! "$(command -v convert)" ]; then
    echo 'imagemagick 未安装'
    check="${check} imagemagick"
  fi

  if [ ! "$(command -v optipng)" ]; then
    echo 'optipng 未安装'
    check="${check} optipng"
  fi

  if [ ! "$(command -v pngquant)" ]; then
    echo 'pngquant 未安装'
    check="${check} pngquant"
  fi

  if [ ! "$(command -v gs)" ]; then
    echo 'ghostscript 未安装'
    check="${check} ghostscript"
  fi

  if [ ! "$(command -v jq)" ]; then
    echo 'jq 未安装'
    check="${check} jq"
  fi

  if [ -n "$check" ]; then
    echo -e "安装依赖工具：\033[34m apt install${check} \033[0m"
    exit 0
  fi
}

checkTool
echo ""
echo -e "--- start compress \033[34m"$folderPath"\033[0m fileSize: \033[31m"$(du -h --max-depth=0 "$folderPath" | cut -f1)"\033[0m  ---"
# 执行compress
compress "$folderPath"
# 获取运行时间
runTme
echo ""
echo -e "--- compress completed \033[34m"$folderPath"\033[0m fileSize: \033[31m"$(du -h --max-depth=0 "$folderPath" | cut -f1)"\033[0m total time: \033[31m"$runtime"\033[0m ---"
exit 0
