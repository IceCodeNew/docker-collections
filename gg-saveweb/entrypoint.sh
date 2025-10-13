#!/usr/bin/env bash

if [[ -z "${subscription_url}" ]]; then
    echo "FATAL: MUST provide the subscription_url for this image to work"
    exit 1
fi
if [[ -z "${ARCHIVIST}" ]]; then
    echo "FATAL: ARCHIVIST must be set"
    exit 1
fi

workloads=("$@")
if [[ "${#workloads[@]}" -le 0 ]]; then
    echo "FATAL: No workloads provided"
    exit 1
fi

gg config -w "subscription=${subscription_url}"
host='ipinfo.io'

# shellcheck disable=SC2016
gg bash -c "
set -ex
echo '
GET / HTTP/1.1
Host: ${host}
User-Agent: curl/7.76.1
Accept: */*
' | nc ${host} 80

for w in ${workloads[*]}; do"'
    echo "Starting workload: ${w}"
    "${w}" &
done

wait -n
exit $?
'
