# How to start

```shell
docker pull icecodexi/ananta:latest
mkdir -p "${HOME}/.ssh/"
touch "$(pwd)/hosts.csv"

if [[ "$UID" -eq '0' ]]; then
    _run_as_root='--user root'
fi
docker run --rm --interactive --tty \
    ${_run_as_root} \
    --volume /etc/localtime:/etc/localtime:ro \
    --volume "${HOME}/.ssh/:/home/nonroot/.ssh/:ro" \
    --volume "$(pwd)/hosts.csv:/home/nonroot/hosts.csv:ro" \
    --cpu-shares 512 --memory 512M --memory-swap 512M \
    icecodexi/ananta:latest \
        --help
```
