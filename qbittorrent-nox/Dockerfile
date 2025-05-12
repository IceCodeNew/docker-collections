# syntax=docker/dockerfile:1

FROM cgr.dev/chainguard/curl:latest-dev AS assets
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /emptydir/
RUN curl -fsSLR --retry 5 --retry-delay 10 --retry-max-time 60 \
    --output qbittorrent-nox \
    "https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/$(arch)-qbittorrent-nox"


FROM mirror.gcr.io/bitnami/python:latest
ADD --link --chmod=0755 \
    'https://raw.githubusercontent.com/qbittorrent/docker-qbittorrent-nox/refs/heads/main/entrypoint.sh' /
COPY --link --from=assets --chmod=0755 /emptydir/ /usr/bin/
RUN install_packages catatonit \
    && groupadd --gid 65532 nonroot \
    && useradd --uid 65532 --gid nonroot --shell /bin/bash --create-home nonroot
USER nonroot:nonroot
WORKDIR /home/nonroot/

EXPOSE 6881/tcp 6881/udp 8080/tcp
VOLUME [ "/config/", "/downloads/" ]
ENTRYPOINT [ "catatonit", "-g", "--", "/entrypoint.sh" ]
