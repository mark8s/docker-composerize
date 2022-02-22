#!/bin/bash

imagesFileName="images.yaml"

imagesTmpFileName="images-bak.yaml"

docker ps -q  > $imagesTmpFileName

imageIds=$(cat ./$imagesTmpFileName)

rm -rf $imagesFileName
touch $imagesFileName

for id in $imageIds
do
  echo $id
  docker inspect --format='{{json .Config.Image}}' $id >> $imagesFileName
done

touch $imagesTmpFileName
echo "#!/usr/bin/env bash" > $imagesTmpFileName

#docker image ls --format "{{.Repository}}:{{.Tag}}" > $imagesFileName

images=$(cat ./$imagesFileName)

ex="export IMAGE_"

for image in $images
do
  imageName="$image"
  if [[ $image =~ "/" ]]
  then
  # 截取最后一个 / 之后的内容
  imageName=${image##*/}
  fi
  # 截取 : 之前的内容
  name=${imageName%%:*}
  # - 替换为 _
  _name=${name//-/_}
  # 转大写
  dxName=${_name^^}
  dxName=${dxName//\"}

  # 拼接
  finalName=$ex$dxName"="$image

 echo $finalName >> $imagesTmpFileName

done

mv $imagesTmpFileName $imagesFileName
echo "over!"