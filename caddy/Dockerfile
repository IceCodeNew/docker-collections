# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/library/caddy:2.11.4@sha256:af5fdcd76f2db5e4e974ee92f96ee8c0fc3edb55bd4ba5032547cbf3f65e486d AS caddy
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

# renovate: datasource=github-releases depName=caddy packageName=caddyserver/caddy
ARG CADDY_VERSION=v2.11.4
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
