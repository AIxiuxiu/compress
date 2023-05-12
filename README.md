# 压缩图片、PDF、视频的 shell 脚本

因为网站图片上传没有限制大小，且未对图片等资源进行处理，导致上传的图片都是照片原图，网站打开很慢

因为已经上传了很多，需要在服务器进行压缩处理

## compress.sh

使用 imagemagick 对图片进行初步处理，限制宽度最大为 1920，因为有长图，所以对高度不进行限制
压缩后发现还有很多 png 图片很大，所有对 png 进行了特殊处理

1. 第一步对使用`optipng`进行无损压缩
2. 第二步使用`pngquant`进行有损压缩
3. 对仍然很大的图片上传到`tinypng`进行处理

> 因为服务器只需要压缩图片和 pdf,所以把压缩 pdf 的代码加入到`compress.sh`中

## compress-pdf.sh

使用 ghostscript 对文件中的 pdf 进行压缩,

## compress-video.sh

使用`ffmpeg`对视频进行压缩

> 因网站视频都是已压缩的视频，所以当前脚本未运行，代码可能有问题

## 优化

当前脚本是全部文件压缩，如果需要定时去压缩新的文件可以增加参数，使用`find`的`mtime`参数查询最近修改的文件压缩
