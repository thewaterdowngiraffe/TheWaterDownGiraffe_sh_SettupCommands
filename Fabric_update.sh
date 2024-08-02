sudo systemctl stop minecraft
VERSION=$(curl -X GET "https://meta.fabricmc.net/v2/versions/" -H  "accept: application/json" | jq '[.game[] | select(.stable == true)][0] |.version')
LOADER=$(curl -X GET "https://meta.fabricmc.net/v2/versions/loader/" -H  "accept: application/json" | jq '[.[] | select(.stable == true)][0] |.version')
INSTALLER=$(curl -X GET "https://meta.fabricmc.net/v2/versions/installer/" -H  "accept: application/json" | jq '[.[] | select(.stable == true)][0] |.version')
INSTALLER="${INSTALLER%\"}"
INSTALLER="${INSTALLER#\"}"
VERSION="${VERSION%\"}"
VERSION="${VERSION#\"}"
LOADER="${LOADER%\"}"
LOADER="${LOADER#\"}"


cd minecraft
rm minecraftServer.jar
curl -o minecraftServer.jar -X GET "https://meta.fabricmc.net/v2/versions/loader/${VERSION}/${LOADER}/${INSTALLER}/server/jar" 
sudo systemctl start minecraft
