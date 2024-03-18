#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo apt-get install wget -y
sudo apt install jq curl openjdk-21-jdk -y


#makes new user and runs it under the new user, comment out to run as current user
#sudo adduser minecraft
#sudo su - minecraft

mkdir minecraft
cd minecraft

# gets the most recent paper mc version
VERSION=$(curl -X GET "https://papermc.io/api/v2/projects/paper" -H  "accept: application/json" | jq '.versions[-1]')
#remove quotes 
VERSION="${VERSION%\"}"
VERSION="${VERSION#\"}"
DIR=$(pwd)
LATEST_BUILD=$(curl -X GET "https://papermc.io/api/v2/projects/paper/versions/${VERSION}" -H  "accept: application/json" | jq '.builds[-1]')


#most recent papermc version


echo -e "paperMC version: ${VERSION}
Current Build: ${LATEST_BUILD}" >> log.txt
echo -e "Download link: https://api.papermc.io/v2/projects/paper/versions/${VERSION}/builds/${LATEST_BUILD}/downloads/paper-${VERSION}-${LATEST_BUILD}.jar" >> log.txt


curl -o paperclip.jar -X GET "https://api.papermc.io/v2/projects/paper/versions/${VERSION}/builds/${LATEST_BUILD}/downloads/paper-${VERSION}-${LATEST_BUILD}.jar" -H  "accept: application/java-archive" -JO
#wget https://api.papermc.io/v2/projects/paper/versions/${VERSION}/builds/${LATEST_BUILD}/downloads/paper-${VERSION}-${LATEST_BUILD}.jar

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
java -Xms${MIN_RAM}G -Xmx${MAX_RAM}G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar paperclip.jar nogui
echo 'restarting in 10'
sleep 10
done">>start.sh


echo "start.sh file config:
" >>log.txt
cat start.sh >> log.txt
echo "

" >> log.txt

#first launch will terminate as eula isnt set to true
java -jar paperclip.jar
#/etc/syste

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



# commands to run in terminal 

# first run : systemctl stop minecraft.service
# then run: bash /minecraft/start.sh 
# let the server boot, you should see a > once its done and should be able to join it at the ip address
# ip address can be found by running "ip a"

#in the console you will be able to run the following commands
#op @a 
#this will give everyone who is on the server op powers. when you run this make sure you are the only one on or replace the @a with your minecraft name

#these can be run in game if you are an op. or you can run them in the command line like the op @a command

#gamerule playersSleepingPercentage 1 
#Gamerule spawnRadius is now set to: 3

