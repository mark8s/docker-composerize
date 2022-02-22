#!/bin/bash

imagesFileName="images.yaml"

imagesTmpFileName="images.yaml.tmp"

touch $imagesTmpFileName
echo "#!/usr/bin/env bash" > $imagesTmpFileName

rm -rf $imagesFileName

docker image ls --format "{{.Repository}}:{{.Tag}}" > $imagesFileName

images=$(cat ./$imagesFileName)

ex="export IMAGE_"

for image in $images
do        
  # 截取最后一个 / 之后的内容
  imageName=${image##*/}
  # 截取 : 之前的内容
  name=${imageName%%:*}
  # - 替换为 _
  _name=${name//-/_}
  # 转大写
  dxName=${_name^^} 
  # 拼接
  finalName=$ex$dxName"="$image 

 echo $finalName >> $imagesTmpFileName 
  
done

mv $imagesTmpFileName $imagesFileName
echo "over!"
