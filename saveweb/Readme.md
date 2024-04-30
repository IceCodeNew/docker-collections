```bash
sudo docker pull containrrr/watchtower
sudo docker rm -f watchtower \
    && sudo docker run -d \
    -v /var/run/docker.sock:/var/run/docker.sock -v /etc/localtime:/etc/localtime:ro \
    -e 'TZ=Asia/Taipei' \
    -e 'WATCHTOWER_CLEANUP=true' \
    -e 'WATCHTOWER_POLL_INTERVAL=4800' \
    -e 'WATCHTOWER_INCLUDE_STOPPED=true' \
    -e 'WATCHTOWER_REVIVE_STOPPED=true' \
    --name watchtower --restart unless-stopped \
    containrrr/watchtower

export ARCHIVIST=icn
docker pull icecodexi/saveweb:huashijie \
    && docker rm -f huashijie \
    && docker run --name huashijie --restart always -e ARCHIVIST="$ARCHIVIST" -d -it icecodexi/saveweb:huashijie
docker pull icecodexi/saveweb:lowapk-v2 \
    && docker rm -f lowapk \
    && docker run --name lowapk    --restart always -e ARCHIVIST="$ARCHIVIST" -d -it icecodexi/saveweb:lowapk-v2
```
