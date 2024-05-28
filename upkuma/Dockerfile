# syntax=docker/dockerfile:1

FROM golang:buster AS graftcp-builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p '/etc/dpkg/dpkg.cfg.d' '/etc/apt/apt.conf.d' \
    && echo 'force-unsafe-io' > '/etc/dpkg/dpkg.cfg.d/docker-apt-speedup' \
    && echo 'Acquire::Languages "none";' > '/etc/apt/apt.conf.d/docker-no-languages' \
    && echo -e 'Acquire::GzipIndexes "true";\nAcquire::CompressionTypes::Order:: "gz";' > '/etc/apt/apt.conf.d/docker-gzip-indexes' \
    && apt-get update -qq \
    && apt-get -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false purge \
        libpython-stdlib libpython2-stdlib libpython2.7-minimal libpython2.7-stdlib python python-minimal python2 python2-minimal python2.7 python2.7-minimal \
        mercurial mercurial-common \
        mime-support \
    && apt-get -y --no-install-recommends install \
        ca-certificates \
        git \
        binutils build-essential coreutils file netbase \
        ucf \
    && apt-get full-upgrade -y \
    && apt-get clean \
    && rm -rf /var/cache/apt/* \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /emptydir/
WORKDIR /git/graftcp/
ENV CFLAGS="-O2 -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs" \
  CXXFLAGS="-O2 -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs"
RUN git clone -j "$(nproc)" --no-tags --shallow-submodules --recurse-submodules --depth 1 --single-branch \
        https://github.com/hmgle/graftcp.git ./
RUN go env -w GOFLAGS="$GOFLAGS -buildmode=pie" \
    && go env -w GO111MODULE=on \
    && make \
    && make install \
    && rm -rf /git/graftcp/ /go/ /root/.cache/


FROM louislam/uptime-kuma:1 AS builder
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


FROM scratch
COPY --link --from=builder                     /  /
COPY --link --from=graftcp-builder --chmod=755 /usr/local/bin/graftcp /usr/local/bin/graftcp-local /usr/local/bin/mgraftcp \
                                               /usr/local/bin/
ENV TZ=Asia/Taipei
ENV UPTIME_KUMA_IS_CONTAINER=1

ENTRYPOINT [ "/usr/local/bin/mgraftcp" ]
CMD [ "extra/entrypoint.sh", "node", "server/server.js" ]

WORKDIR /app/
VOLUME ["/app/data"]
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=5 CMD extra/healthcheck
