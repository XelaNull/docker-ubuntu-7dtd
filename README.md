This project seeks to create a better 7DTD Gameserver platform that can be configured and managed from the built-in webserver. This project results in a 7dtd Linux game server with:

- COMPO-PACK
- Over 450 Modlets available for easy activation, including Alloc's Server Fixes, ServerTools, Bad Company, CSMM Patrons, The Wild Land, and many more
- Web Interface to manage your server, featuring:

  - Start/Stop/Force Stop 7DTD Gameserver
  - View Gameserver log
  - Edit serverconfig.xml or any XML under Data/Config
  - Nearly 500 modlets pre-installed, easily activated/deactivated with just a check/uncheck and restart of your gameserver
  - Auto-Exploration of World rendered map
  - RWG World Analysis with stats to inform you on the placement of prefabs within your randomly generated world seed
  - Authentication utilizes 7DTD Telnet password, to keep the configuration simple

**Future features:**

- Backup/Restore of Modlet selections & Game Saves
- Better game update support, without full wipe
- Update individual Modlet or all Modlets, from web interface
- Improved log viewer
- Improved server status

# TO BUILD

**_Be sure to copy these command carefully!_**

```
time docker build \
  --build-arg INSTALL_DIR="/data/7DTD" \
  --build-arg TELNET_PW="sanity" \
  -t u18/7dtd .
```

# TO RUN

First, create a Steam account specifically for your server. Use these credentials below.

```
docker run -dt -v$(pwd)/data:/data \
  -p26900:26900/udp -p26900:26900/tcp -p26902:26902/udp \
  -p80:80 -p8080:8080 -p8081:8081 -p8082:8082 \
  -e STEAMCMD_LOGIN=YOUR_STEAM_USERNAME \
  -e STEAMCMD_PASSWORD='YOUR_STEAM_PASSWORD' \
  -e STEAMCMD_APP_ID=294420 -e 7DTD_AUTOREVEAL_MAP=true \

  --name=u18-7dtd u18/7dtd
```

# TO INSTALL STEAM GAME

This command will initiate a Steam Guard request and require you to type in the code that Steam emails you. When this command completes, your server will begin generating a new world and will start the server.

```
docker exec -it u18-7dtd /install_7dtd.sh
```

# TO ENTER

```
docker exec -it u18-7dtd bash
```
