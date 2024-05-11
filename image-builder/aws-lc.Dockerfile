# syntax=docker/dockerfile:1

FROM golang:bullseye AS base
ARG DEBIAN_FRONTEND=noninteractive
ARG image_build_date='2024-05-11'
# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir -p '/etc/dpkg/dpkg.cfg.d' '/etc/apt/apt.conf.d' \
    && echo 'force-unsafe-io' > '/etc/dpkg/dpkg.cfg.d/docker-apt-speedup' \
    && echo 'Acquire::Languages "none";' > '/etc/apt/apt.conf.d/docker-no-languages' \
    && echo -e 'Acquire::GzipIndexes "true";\nAcquire::CompressionTypes::Order:: "gz";' > '/etc/apt/apt.conf.d/docker-gzip-indexes' \
    && apt-get update -qq && apt-get full-upgrade -y \
    && apt-get -y install \
        ca-certificates curl gpg gpg-agent \
    && curl -sSL 'https://apt.llvm.org/llvm-snapshot.gpg.key' > /etc/apt/trusted.gpg.d/apt.llvm.org.asc \
    && echo 'deb http://apt.llvm.org/bullseye/ llvm-toolchain-bullseye main' > /etc/apt/sources.list.d/llvm.list \
    && echo 'deb http://deb.debian.org/debian bullseye-backports main' > /etc/apt/sources.list.d/backports.list \
    && apt-get update -qq \
    && apt-get -y install \
        binutils build-essential coreutils dos2unix file git libarchive-tools netbase pkgconf util-linux \
        clang \
        cmake ninja-build \
        perl \
    && apt-get -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false purge \
    && apt-get clean \
    && rm -rf /var/cache/apt/* \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/local/bin/pkg-config pkg-config /usr/bin/pkgconf 100 \
    && update-alternatives --auto pkg-config


FROM base AS golang-builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/rui314/mold/releases/latest
ARG mold_latest_tag_name='v2.31.0'
RUN curl --retry 5 --retry-delay 10 --retry-max-time 60 -fsSL \
        "https://github.com/rui314/mold/releases/download/${mold_latest_tag_name}/mold-${mold_latest_tag_name#v}-x86_64-linux.tar.gz" \
        | bsdtar -xf- --strip-components 1 -C /usr \
    && update-alternatives --install /usr/bin/ld ld /usr/bin/ld.mold 100 \
    && update-alternatives --auto ld


FROM golang-builder AS aws-lc-builder
ARG image_build_date='2024-05-11'
ARG REPOPATH="github.com/aws/aws-lc"
WORKDIR /go/src/${REPOPATH}/
RUN git clone -j "$(nproc)" --no-tags --shallow-submodules --recurse-submodules --depth 1 --single-branch \
        "https://${REPOPATH}" ./

ENV CC=clang \
    CXX=clang++ \
    LDFLAGS="-fuse-ld=mold"
# ENV CFLAGS='-O2 -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong' \
#     CXXFLAGS='-O2 -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong'
# ENV PKG_CONFIG_ALL_STATIC=true \
#     PKG_CONFIG="pkgconf --static"
ENV CGO_ENABLED=0
WORKDIR /aws-lc-build/
RUN cmake -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/aws-lc-install \
        -DBUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DFIPS=OFF \
        /go/src/${REPOPATH}/ \
    && ninja install


FROM scratch
COPY --from=aws-lc-builder /aws-lc-install/ /aws-lc-install/
