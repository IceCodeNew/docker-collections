# syntax=mirror.gcr.io/docker/dockerfile:1

FROM mirror.gcr.io/louislam/uptime-kuma:2 AS uptime-kuma
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


FROM mirror.gcr.io/icecodexi/graftcp:latest AS graftcp
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
