# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM cgr.dev/chainguard/curl:latest-dev@sha256:1ddc7963ef89c42431a54a662abf035a0dbdada8e9f929ff459fbdd9ac3cc48c AS assets
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /emptydir/
RUN curl -fsSLR --retry 5 --retry-delay 10 --retry-max-time 60 \
    --output qbittorrent-nox \
    "https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/$(arch)-qbittorrent-nox"


FROM mirror.gcr.io/icecodexi/python:debian-nonroot@sha256:7f85f87ff85fa9f27689b4175ad10a42f7fc6dbe9e1c4b6447da27d5e747f1f4
ADD --link --chmod=0755 \
    'https://raw.githubusercontent.com/qbittorrent/docker-qbittorrent-nox/refs/heads/main/entrypoint.sh' /
COPY --link --from=assets --chmod=0755 /emptydir/ /usr/bin/

EXPOSE 6881/tcp 6881/udp 8080/tcp
VOLUME [ "/config/", "/downloads/" ]
ENTRYPOINT [ "catatonit", "-g", "--", "/entrypoint.sh" ]
