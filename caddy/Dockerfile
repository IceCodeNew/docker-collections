# syntax=docker/dockerfile:1

FROM docker.io/library/caddy:builder AS builder
RUN go env -w GOFLAGS="$GOFLAGS -buildmode=pie" \
    && go env -w GOAMD64=v2 \
    && xcaddy build \
    --with github.com/caddy-dns/cloudflare@master \
    --with github.com/mholt/caddy-l4@master \
    --output "/usr/bin/caddy"

FROM docker.io/library/caddy:latest  AS caddy
RUN apk update; apk --no-progress --no-cache add \
        tzdata; \
    apk --no-progress --no-cache upgrade; \
    rm -rf /var/cache/apk/*;
COPY --from=builder /usr/bin/caddy /usr/bin/caddy


# strip off the published ports
FROM scratch
COPY --link --from=caddy / /

ENV TZ=Asia/Taipei
# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/data

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

ENTRYPOINT [ "/usr/bin/caddy" ]
CMD [ "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile", "--watch" ]
