# syntax=mirror.gcr.io/docker/dockerfile:1

FROM mirror.gcr.io/library/caddy:latest AS caddy
RUN apk update \
    && apk --no-progress --no-cache add \
        catatonit \
        tzdata \
    && apk --no-progress --no-cache upgrade \
    && rm -rf /var/cache/apk/*;
COPY --link --from=local-bin ./caddy /usr/bin/
RUN /usr/bin/caddy version \
    && /usr/bin/caddy list-modules \
    && /usr/bin/caddy build-info


# strip off the published ports
FROM scratch
COPY --link --from=caddy / /

ENV TZ=Asia/Taipei
# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/data

ARG CADDY_VERSION=v2.10.2
ENV CADDY_VERSION=${CADDY_VERSION:-latest}

LABEL org.opencontainers.image.version=$CADDY_VERSION
LABEL org.opencontainers.image.title=Caddy
LABEL org.opencontainers.image.description="a powerful, enterprise-ready, open source web server with automatic HTTPS written in Go"
LABEL org.opencontainers.image.url=https://caddyserver.com
LABEL org.opencontainers.image.documentation=https://caddyserver.com/docs
LABEL org.opencontainers.image.vendor="Light Code Labs"
LABEL org.opencontainers.image.licenses=Apache-2.0
LABEL org.opencontainers.image.source="https://github.com/caddyserver/caddy-docker"

WORKDIR /srv
VOLUME /etc/caddy/
VOLUME /usr/local/etc/caddy/
VOLUME /tmp/unix-socket/

ENTRYPOINT [ "catatonit", "--", "caddy" ]
CMD [ "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile", "--watch" ]
