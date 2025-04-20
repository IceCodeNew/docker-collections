# syntax=docker/dockerfile:1

FROM cgr.dev/chainguard/curl:latest-dev AS assets
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /emptydir/
COPY --link --chmod=0755 ./dummy-tr /emptydir/
RUN curl -fsSLR --retry 5 --retry-delay 10 --retry-max-time 60 \
    --output qbittorrent-nox \
    "https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/$(arch)-qbittorrent-nox" \
    && chmod 0755 /emptydir/qbittorrent-nox \
    && ln -sf /usr/bin/dummy-tr /emptydir/tr


FROM mirror.gcr.io/icecodexi/bash-toybox:latest AS bash-toybox
FROM cgr.dev/chainguard/static:latest
# toybox + bash(ash) + catatonit
COPY --link --from=bash-toybox /usr/bin/ /usr/bin/

ADD --link --chmod=0755 \
    'https://raw.githubusercontent.com/qbittorrent/docker-qbittorrent-nox/refs/heads/main/entrypoint.sh' /
COPY --link --from=assets     /emptydir/ /usr/bin/
SHELL ["/usr/bin/bash", "-o", "pipefail", "-c"]
# the base image already merged /bin/ into /usr/bin/
# RUN rm -rf /bin/ && ln -sf /usr/bin /bin

EXPOSE 6881/tcp 6881/udp 8080/tcp
VOLUME [ "/config/", "/downloads/" ]
ENTRYPOINT [ "catatonit", "-g", "--", "/entrypoint.sh" ]
