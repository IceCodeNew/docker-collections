#!/bin/sh

if [ -z "$subscription_url" ]; then
    echo "FATAL: MUST provide the subscription_url for this image to work"
    exit 1
fi
if [ -z "$ARCHIVIST" ]; then
    echo "FATAL: ARCHIVIST must be set"
    exit 1
fi

gg config -w "subscription=${subscription_url}"
host='ipinfo.io'
{
    echo "GET / HTTP/1.1";
    echo "Host: ${host}";
    echo "User-Agent: curl/7.76.1";
    echo "Accept: */*";
    echo;
} | gg nc "$host" 80

gg "$@"
