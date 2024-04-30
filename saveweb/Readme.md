```bash
export ARCHIVIST=icn
docker pull icecodexi/saveweb:huashijie \
    && docker rm -f huashijie \
    && docker run --name huashijie --restart always -e ARCHIVIST="$ARCHIVIST" -d -it icecodexi/saveweb:huashijie
docker pull icecodexi/saveweb:lowapk-v2 \
    && docker rm -f lowapk \
    && docker run --name lowapk    --restart always -e ARCHIVIST="$ARCHIVIST" -d -it icecodexi/saveweb:lowapk-v2
```
