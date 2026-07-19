# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM cgr.dev/chainguard/curl:latest-dev@sha256:d69f99fa35e2e34fa11c4d021789a1b860c169c1d0eefc0aea4e1dbaea7c21fb AS assets
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /emptydir/
RUN curl -fsSLR --retry 5 --retry-delay 10 --retry-max-time 60 \
    --output qbittorrent-nox \
    "https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/$(arch)-qbittorrent-nox"


FROM mirror.gcr.io/icecodexi/python:debian-nonroot@sha256:e3d007fe4783d964e17041cdfe5f884218581224cc0d1d341e4151942e89c88b
ADD --link --chmod=0755 \
    'https://raw.githubusercontent.com/qbittorrent/docker-qbittorrent-nox/refs/heads/main/entrypoint.sh' /
COPY --link --from=assets --chmod=0755 /emptydir/ /usr/bin/

EXPOSE 6881/tcp 6881/udp 8080/tcp
VOLUME [ "/config/", "/downloads/" ]
ENTRYPOINT [ "catatonit", "-g", "--", "/entrypoint.sh" ]
