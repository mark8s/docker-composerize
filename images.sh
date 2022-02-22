#!/bin/bash

imagesFileName="images.yaml"
imagesTmpFileName="images-bak.yaml"

# 获取运行容器的id 列表
docker ps -q  > $imagesTmpFileName

imageIds=$(cat ./$imagesTmpFileName)

rm -rf $imagesFileName
touch $imagesFileName

# 根据容器id  获取镜像地址
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

# 遍历镜像地址 做一些操作
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
  # 去掉""
  dxName=${dxName//\"}
  # 拼接
  finalName=$ex$dxName"="$image

 echo $finalName >> $imagesTmpFileName

done

mv $imagesTmpFileName $imagesFileName
echo "over!"