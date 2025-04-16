# How to start

```shell
docker pull icecodexi/smartdns:latest
sudo mkdir -p /etc/smartdns/
sudo chmod -R 0644 /etc/smartdns/
docker run --restart always \
    --volume /etc/localtime:/etc/localtime:ro \
    --volume "/etc/smartdns/:/etc/smartdns/ro" \
    --cpu-shares 512 --memory 512M --memory-swap 512M \
    --detach --name smartdns \
    --label=com.centurylinklabs.watchtower.enable=true \
    icecodexi/smartdns:latest
```
