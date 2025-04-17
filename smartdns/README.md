# How to start

```shell
sudo docker pull icecodexi/smartdns:latest

sudo docker stop --timeout 60 smartdns || true
sudo docker rm -f smartdns \
    && sudo docker run --restart always \
        --volume /etc/localtime:/etc/localtime:ro \
        --publish 53:53/udp \
        --cpu-shares 512 --memory 512M --memory-swap 512M \
        --detach --name smartdns \
        --label=com.centurylinklabs.watchtower.enable=true \
        icecodexi/smartdns:latest
```
