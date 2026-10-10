# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM cgr.dev/chainguard/curl:latest-dev@sha256:a32cef27e18adc173e8b2a84036fac932f2e176347ab3ea20a074e3569185c15 AS assets
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
