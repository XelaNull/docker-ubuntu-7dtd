This project seeks to create a website-controlled 7DTD Game server platform that anyone can install and use. The intent is this should be simple enough to install that anyone with access to a Linux server with Docker installed can accomplish this.

**Current features of this project:**

- [7DTD-ServerMod Manager](https://github.com/XelaNull/7dtd-servermod) : Web Interface to manage your server

  - Start/Stop/Force Stop 7DTD Game server
  - View Game server log
  - Edit serverconfig.xml or any XML under Data/Config
  - Easy activation of pre-installed modlets
  - [Auto-Exploration of Map](https://github.com/XelaNull/7dtd-auto-reveal-map)
  - Random-World-Generation analysis to inform you on the placement of prefabs within your generated random seed
  - Authentication utilizes 7DTD Telnet password, to keep the configuration simple

- COMPO-PACK Prefabs installed, providing over 250 new buildings. Suggest using Modlet 'The Wild Land' to implement the Prefabs for placement during RWG.
- Over 450 Modlets pre-installed for easy activation, including Alloc's Server Fixes, ServerTools, Bad Company, CSMM Patrons, The Wild Land, and many more

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
  --build-arg TELNET_PW="YOUR_TELNET_PASSWORD" \
  -t u18/7dtd .
```

# TO RUN

**_Create a Steam account specifically for your server. Use these credentials below._**

```
docker run -dt -v$(pwd)/data:/data \
  -p26900:26900/udp -p26900:26900/tcp -p26902:26902/udp \
  -p80:80 -p8080:8080 -p8081:8081 -p8082:8082 \
  -e STEAMCMD_LOGIN=YOUR_STEAM_USERNAME \
  -e STEAMCMD_PASSWORD='YOUR_STEAM_PASSWORD' \
  -e STEAMCMD_APP_ID=294420 -e 7DTD_AUTOREVEAL_MAP=true \
  --name=u18-7dtd u18/7dtd
```

# TO INSTALL STEAM GAME: 7 Days to Die

This command will initiate a Steam Guard request and require you to type in the code that Steam emails you. When this command completes, your server will begin generating a new world and will start the server.

```
docker exec -it u18-7dtd /install_7dtd.sh
```

# TO ENTER

```
docker exec -it u18-7dtd bash
```
