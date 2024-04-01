#!/bin/bash
#enter one minecraft username to set it as the OP or leave it empty and dont set any
USER=$""

sudo apt update && sudo apt upgrade -y
sudo apt-get install wget -y
sudo apt install jq curl openjdk-21-jdk -y


#makes new user and runs it under the new user, comment out to run as current user
#sudo adduser minecraft
#sudo su - minecraft

mkdir minecraft
cd minecraft







# gets the most recent paper mc version

VERSION=$(curl -X GET "https://meta.fabricmc.net/v2/versions/" -H  "accept: application/json" | jq '[.game[] | select(.stable == true)][0] |.version')
LOADER=$(curl -X GET "https://meta.fabricmc.net/v2/versions/loader/" -H  "accept: application/json" | jq '[.[] | select(.stable == true)][0] |.version')
INSTALLER=$(curl -X GET "https://meta.fabricmc.net/v2/versions/installer/" -H  "accept: application/json" | jq '[.[] | select(.stable == true)][0] |.version')
INSTALLER="${INSTALLER%\"}"
INSTALLER="${INSTALLER#\"}"
VERSION="${VERSION%\"}"
VERSION="${VERSION#\"}"
LOADER="${LOADER%\"}"
LOADER="${LOADER#\"}"








DIR=$(pwd)



#most recent fabricmc version


echo -e "fabricmc version: ${VERSION}
Current Build: ${LATEST_BUILD}" >> log.txt
echo -e "Download link: https://meta.fabricmc.net/v2/versions/loader/${VERSION}/${LOADER}/${INSTALLER}/server/jar" >> log.txt


curl -o minecraftServer.jar -X GET "https://meta.fabricmc.net/v2/versions/loader/${VERSION}/${LOADER}/${INSTALLER}/server/jar" 


#get available memmory in kb
RAM=$(grep MemTotal /proc/meminfo)
RAM=${RAM//[!0-9]/}
MAX_RAM=$( expr ${RAM} \/ 1100000)
MIN_RAM=$( expr ${RAM} \/ 1100000)

echo -e "${MAX_RAM}G ${MIN_RAM}G"
#makes the start script


echo -e "
#!/bin/bash
cd ${DIR}
while true
do
java -Xms${MIN_RAM}G -Xmx${MAX_RAM}G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar minecraftServer.jar nogui
echo 'restarting in 10'
sleep 10
done">>start.sh


echo "start.sh file config:
" >>log.txt
cat start.sh >> log.txt
echo "

" >> log.txt

#first launch will terminate as eula isnt set to true
java -jar minecraftServer.jar


if [ ! $USER = "" ]; then
  UUID=$(curl -X GET "https://api.mojang.com/users/profiles/minecraft/${USER}" | jq '.id')
  UUID="${UUID%\"}"
  UUID="${UUID#\"}"
  UUID=$"${UUID:0:8}-${UUID:8:4}-${UUID:12:4}-${UUID:16:4}-${UUID:20:12}"

  echo "
  [
    {
      'uuid':'${UUID}',
      'name':'${USER}',
      'level': 4,
      'bypassPlayerLimit': false
    }
  ]" > ops.json
fi


if test -f ../server.properties; then
  cat ../server.properties > server.properties
fi

#upate eula
chmod +x start.sh

# update eula
sed '3, $ d' eula.txt > tmp.txt && mv tmp.txt eula.txt
echo "eula=true" >> eula.txt

#get plugins
#https://docs.papermc.io/paper/adding-plugins

#./start.sh

sudo touch /etc/systemd/system/minecraft.service

sudo echo "
[Unit]
StartLimitBurst=5
StartLimitIntervalSec=100

Description=This is the Paper MC server
After=network.target
StartLimitIntervalSec=10

[Service]
Type=simple
Restart=on-failure
RestartSec=10
ExecStart=/bin/bash -c ${DIR}/start.sh

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/minecraft.service
sudo systemctl daemon-reload 

sudo systemctl start minecraft
sudo systemctl enable minecraft

echo "service file:

" >> log.txt
cat /etc/systemd/system/minecraft.service >> log.txt
echo "

" >> log.txt

