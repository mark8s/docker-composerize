#!/bin/bash

imagesFileName="image-package.yaml"
imagesTmpFileName="image-package-bak.yaml"
cur_date="`date +%Y-%m-%d`"
imagePackageName="image-"$cur_date".tar"

# 获取运行容器的id 列表
docker ps -q  > $imagesTmpFileName

imageIds=$(cat ./$imagesTmpFileName)

rm -rf $imagesFileName
touch $imagesFileName

echo "Now, some ids representing the containers to be processed are printed below"

# 根据容器id  获取镜像地址
for id in $imageIds
do
  echo $id
  docker inspect --format='{{json .Config.Image}}' $id >> $imagesFileName
done

# 将换行更换为空格
cat $imagesFileName | tr "\n" " " > $imagesTmpFileName

mv $imagesTmpFileName $imagesFileName

# 保存容器镜像

images=$(cat ./$imagesFileName)
# 去掉双引号
images=${images//\"}

rm -rf $imagePackageName

echo "Image packing begins. Please wait"

docker save -o $imagePackageName $images

echo "Image Package Name is " $imagePackageName  ". You can check it. "
echo "over!"
