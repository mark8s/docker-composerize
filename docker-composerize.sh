#!/bin/bash

timer_start=`date "+%Y-%m-%d %H:%M:%S"`

containerFileName="container-names.txt"
dockerEnvFileName="docker-run-env.txt"
composerizeEnvFile="docker-composerize.yaml"
composerizeEnvFileTmp="docker-composerize.yaml.tmp"
envFileName="env.sh"

# 获取正在运行的容器id和容器名称，格式为 id=name
docker ps --format "table {{.ID}}={{.Names}}"  > $containerFileName

echo "--------- start ---------- "
containers=$(cat ./$containerFileName)

rm -rf $dockerEnvFileName
rm -rf $composerizeEnvFile

for c in $containers
do
    if [[ $c =~ "CONTAINER" ]]
    then
       continue
    fi

    if [[ $c =~ "ID=NAMES" ]]
    then
       continue
    fi
    # 得到容器id，以等号分隔
    id=${c%%=*}
    # 得到容器名称
    name=${c#*=}
    # 通过容器id获取容器运行参数以及命令
    docker-papa container -c $id > $dockerEnvFileName
    # 替换命令为composerize docker run
    sed -i 's/.*docker run/composerize docker run/g' $dockerEnvFileName
    # 截取容器名得到services名
    containerName=${name#*name}
    serviceName=$containerName
    if [[ $containerName =~ "k8s_POD" ]]
    then
      containerName=${containerName#*k8s_POD_}
    else
      containerName=${containerName#*k8s_}
    fi

    containerName=${containerName%%_*}
    serviceName=$containerName

    # 在每行的末尾一个services名
    sed -i "s/$/ $serviceName/g" $dockerEnvFileName

    #echo  $(cat ./$dockerEnvFileName)

    $(cat ./$dockerEnvFileName) >> $composerizeEnvFile

    echo "service:   "  $serviceName

done

rm -rf $containerFileName
rm -rf $dockerEnvFileName

# 删除多余的"version:"和"services:"字段
sed -i "/version:/d" $composerizeEnvFile
sed -i "/services:/d" $composerizeEnvFile

# 在第一行分别增加"version:"和"services:"字段
sed -i '1i\services:' $composerizeEnvFile
sed -i "1i\version: '3.0'" $composerizeEnvFile

envs=$(cat ./$envFileName)
for env in $envs
do
  if [ $env != "export" ]
  then
    envKey=${env%%=*}
    envValue=${env#*=}

  # 替换env.sh中value和compose文件中相同的值，并且compose中值的格式为${env.sh中key的名称}，如：${LC_MYSQL_ROOT_PASSWORD}
    sed  "s|$envValue|\${$envKey}|g" $composerizeEnvFile > $composerizeEnvFileTmp
    mv $composerizeEnvFileTmp $composerizeEnvFile
fi

done

echo "--------- end ---------- "

timer_end=`date "+%Y-%m-%d %H:%M:%S"`

duration=`echo $(($(date +%s -d "${timer_end}") - $(date +%s -d "${timer_start}"))) | awk '{t=split("60 s 60 m 24 h 999 d",a);for(n=1;n<t;n+=2){if($1==0)break;s=$1%a[n]a[n+1]s;$1=int($1/a[n])}print s}'`
echo "start: " $timer_start
echo "end: " $timer_end
echo "spend: " $duration
