#!/bin/bash

# 最大码率 默认 2500 kbits/s
MAX_BITRATE=$((2500 * 1024))

# 最大宽度和高度
MAX_WIDTH=1920
MAX_HEIGHT=1080

# 指定输出的视频质量，会影响文件的生成速度，可用值 ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow。
preset="fast"


# 视频编码器，默认最流行的开源 H.264 编码器
vcodec="libx264"
# 压缩参数，取值：1-51，值越小越清晰但体积越大，一般18-26
crf=20

function getVideoInfo() {
    media=$1
    width=$(ffprobe -hide_banner -v error -select_streams v:0 -show_entries stream=width -of default=nk=1:nw=1 $media)
    height=$(ffprobe -hide_banner -v error -select_streams v:0 -show_entries stream=height -of default=nk=1:nw=1 $media)
    video_bitrate=$(ffprobe -hide_banner -v error -select_streams v:0 -show_entries stream=bit_rate -of default=nk=1:nw=1 $media)
    audio_bitrate=$(ffprobe -hide_banner -v error -select_streams a:0 -show_entries stream=bit_rate -of default=nk=1:nw=1 $media)
    video_rotation=$(ffprobe -hide_banner -v error -select_streams v:0 -show_entries stream_side_data=rotation -of csv=p=0 $media)
    fullname=$(basename "$media")

    echo "开始处理 "$fullname""
    echo "Width: ${width}"
    echo "Height: ${height}"
    echo "Video bitrate: $((video_bitrate / 1024)) kbits/s"
    echo "Audio bitrate: $((audio_bitrate / 1024)) kbits/s"
}

params=""
# 转换成固定高宽比视频
function getFixedRatioVideo() {
    # 视频宽高比
    a=16
    b=9
    # 黑边颜色 默认: "black"
    color="black"

    asp_ratio=$(bc <<<"scale=5;$width/$height")
    ENDRATIO=$(bc <<<"scale=5;$a/$b")

    echo "Ratio: ${asp_ratio}"
    echo "${a}/${b}: ${ENDRATIO}"

    nw=$width
    nh=$height

    # 转换宽高比 默认: a=16, b=9
    if [ $(bc <<<"$asp_ratio < $ENDRATIO") -eq 1 ]; then

        nw=$(/usr/bin/printf "%.0f" $(bc <<<"scale=5;$ENDRATIO*$height"))

        if ((nw % 2 == 1)); then
            ((nw += 1))
        fi

        temp=$(($nw - $width))

        if ((nw > MAX_WIDTH)) || ((nh > MAX_HEIGHT)); then
            temp=$((temp * MAX_WIDTH / nw))
            nw=$(($MAX_WIDTH - $temp))
            nh=$MAX_HEIGHT
            width=$nw
            if [ $DEBUG -eq 1 ]; then
                echo "SCALING A VERTICAL VIDEO!!!!!!!!!!!!!!!!!!!!!!!! temp: ${temp}"
            fi
        fi
        params="-filter_complex [0:v]scale=$width:$nh,pad=w=$temp+iw:x=$(($temp / 2)):color=$color"

    elif [ $(bc <<<"$asp_ratio > $ENDRATIO") -eq 1 ]; then

        nh=$(/usr/bin/printf "%.0f" $(bc <<<"scale=5;(1/$ENDRATIO)*$width"))

        if ((nh % 2 == 1)); then
            ((nh += 1))
        fi

        temp=$(($nh - $height))

        if ((nw > MAX_WIDTH)) || ((nh > MAX_HEIGHT)); then
            temp=$((temp * MAX_WIDTH / nw))
            nw=$MAX_WIDTH
            nh=$(($MAX_HEIGHT - $temp))
            height=$nh
            if [ $DEBUG -eq 1 ]; then
                echo "SCALING A GORIZONTAL VIDEO!!!!!!!!!!!!!!!!!!!!!!!! temp: ${temp}"
            fi
        fi
        params="-filter_complex [0:v]scale=$nw:$height,pad=h=$temp+ih:y=$(($temp / 2)):color=$color"

    fi

    if ((nw > MAX_WIDTH)) || ((nh > MAX_HEIGHT)); then
        nw=$MAX_WIDTH
        nh=$MAX_HEIGHT
        params="-vf scale=$nw:$nh"
        if [ $DEBUG -eq 1 ]; then
            echo "~~~~~~~~~~~~~~~~~~~~~~ASPECT RATIO ALREADY ${a}:${b}~~~~~~~~~~~~~~~~~~~~~~"
        fi
    fi
}

# 转换成固定高宽比视频
function getVideoWH() {
    nw=${width%%,}
    nh=${height%%,}
    video_rotation=${video_rotation%%,}
    [ "$video_rotation" ] || video_rotation=0

    if [ "$nw" -gt "$nw" ] && [ "${video_rotation##-}" != 90 ]; then
        [ "$nw" -gt 1280 ] && nw=1280
        nw=-1
        echo "$1 is horizontal video; scaling to $nw x $nh"
    else
        nw=-1
        [ "$nh" -gt 1280 ] && nh=1280
        echo "$1 is vertical video; scaling to $nw x $nh"
    fi
    params="-vf scale=$nw:$nh"
}


sourcedir="$1"

if [ ! -d "$sourcedir" ]; then
    echo -e "\033[34m$sourcedir\033[0m目录不存在"
    exit 1
fi

if [ ! "$(command -v ffmpeg)" ]; then
    echo -e "没有安装 ffmpeg，安装：\033[34m apt install FFmpeg \033[0m"
    exit 1
fi

destdir="$sourcedir/compressed"
if [ ! -d "$destdir" ]; then
    mkdir -p -- "$destdir"
fi
# 开始遍历目录内媒体文件
# filelist=$(find "$sourcedir" -path "$destdir" -prune -type f -o -iname "*.mp4")
filelist=$(
    find "$sourcedir" -path "$destdir" -prune -type f \
        -o -iname "*.mp4" \
        -o -iname "*.mov" \
        -o -iname "*.webm" \
        -o -iname "*.avi" \
        -o -iname "*.wmv" \
        -o -iname "*.m4v" \
        -o -iname "*.flv" \
        -o -iname "*.rm" \
        -o -iname "*.rmvb" \
        -o -iname "*.vob" \
        -o -iname "*.mkv"
)

for media in $filelist; do
    # 开始计时
    startTime=$(date +"%Y-%m-%d %H:%M:%S")

    # 获取视频信息
    getVideoInfo $media
    # 获取视频宽高
    getVideoWH

    # 修改码率
    bitrate_to_set=$video_bitrate
    if (($video_bitrate > MAX_BITRATE)); then
        bitrate_to_set=$MAX_BITRATE
    fi

    output="$destdir/${filename}"

    # threads 编码器使用的线程数
    ffmpeg \
        -i $media \
        -preset $preset \
        -threads 4 \
        $params \
        -c:v $vcodec \
        -crf $crf \
        -b:v $bitrate_to_set \
        $output -y >/dev/null 2>&1

    # 计算文件压缩前后体积
    osize=$(du -h "$media" | cut -f1)
    fsize=$(du -h "$output" | cut -f1)
    # 结束计时
    endTime=$(date +"%Y-%m-%d %H:%M:%S")
    st=$(date -d "$startTime" +%s)
    et=$(date -d "$endTime" +%s)
    sumTime=$((et - st))
    echo "  └─原体积：$osize  压缩后：$fsize"
    echo "  └─本次压缩耗费 $sumTime 秒"
done
