#!/bin/bash

timer_start=`date "+%Y-%m-%d %H:%M:%S"`

containerFileName="container-names.txt"
dockerEnvFileName="docker-run-env.txt"
composerizeEnvFile="docker-composerize.yaml"
composerizeEnvFileTmp="docker-composerize.yaml.tmp"
envFileName="env.sh"

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

    id=${c%%=*}
    name=${c#*=} 
     
    docker-papa container -c $id > $dockerEnvFileName
    sed -i 's/docker run/composerize docker run/g' $dockerEnvFileName
 
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
    
    sed -i "s/$/ $serviceName/g" $dockerEnvFileName  
       
    $(cat ./$dockerEnvFileName) >> $composerizeEnvFile     
    
    echo "service:   "  $serviceName

done 

rm -rf $containerFileName
rm -rf $dockerEnvFileName

# delete redundant fields
sed -i "/version:/d" $composerizeEnvFile
sed -i "/services:/d" $composerizeEnvFile

# add
sed -i '1i\services:' $composerizeEnvFile
sed -i "1i\version: '3.0'" $composerizeEnvFile

envs=$(cat ./$envFileName)
for env in $envs
do
  if [ $env != "export" ]
  then 
    envKey=${env%%=*}
    envValue=${env#*=}
    
  #  envKey=$(trim $envKey)
  #  envValue=$(trim $envValue) 
    
  #  echo "key: " $envKey
  #  echo "value: " $envValue
  # replace env var
    sed  "s|=$envValue|=\${$envKey}|g" $composerizeEnvFile > $composerizeEnvFileTmp
    mv $composerizeEnvFileTmp $composerizeEnvFile
    
fi

done

echo "--------- end ---------- "

timer_end=`date "+%Y-%m-%d %H:%M:%S"`

duration=`echo $(($(date +%s -d "${timer_end}") - $(date +%s -d "${timer_start}"))) | awk '{t=split("60 s 60 m 24 h 999 d",a);for(n=1;n<t;n+=2){if($1==0)break;s=$1%a[n]a[n+1]s;$1=int($1/a[n])}print s}'`
echo "start: " $timer_start
echo "end: " $timer_end
echo "spend: " $duration



