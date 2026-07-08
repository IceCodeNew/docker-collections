# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/louislam/uptime-kuma:1.23.16@sha256:431fee3be822b04861cf0e35daf4beef6b7cb37391c5f26c3ad6e12ce280fe18 AS uptime-kuma
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p '/etc/dpkg/dpkg.cfg.d' '/etc/apt/apt.conf.d' \
    && echo 'force-unsafe-io' > '/etc/dpkg/dpkg.cfg.d/docker-apt-speedup' \
    && echo 'Acquire::Languages "none";' > '/etc/apt/apt.conf.d/docker-no-languages' \
    && echo -e 'Acquire::GzipIndexes "true";\nAcquire::CompressionTypes::Order:: "gz";' > '/etc/apt/apt.conf.d/docker-gzip-indexes' \
    && apt-get update -qq && apt-get full-upgrade -y \
    && apt-get -y --no-install-recommends install \
        ca-certificates \
    && apt-get -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false purge \
    && apt-get clean \
    && rm -rf /var/cache/apt/* \
    && rm -rf /var/lib/apt/lists/*


FROM mirror.gcr.io/icecodexi/graftcp:latest@sha256:92c574521e180f7dc124c57da1d1493daad1dcfd92bf179b1f13caf29025bf30 AS graftcp
FROM scratch
COPY --link --from=uptime-kuma         /               /
COPY --link --from=graftcp --chmod=755 /usr/local/bin/ /usr/local/bin/
ENV TZ=Asia/Taipei
ENV UPTIME_KUMA_IS_CONTAINER=1

ENTRYPOINT [ "/usr/local/bin/mgraftcp" ]
CMD [ "extra/entrypoint.sh", "node", "server/server.js" ]

WORKDIR /app/
VOLUME ["/app/data"]
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=5 CMD extra/healthcheck
