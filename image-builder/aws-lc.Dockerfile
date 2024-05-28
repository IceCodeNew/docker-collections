# syntax=docker/dockerfile:1

FROM golang:alpine AS golang-builder
ARG image_build_date='2024-05-11'
# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apk update \
    && apk --no-cache add \
        bash \
        ca-certificates curl grep sed \
        coreutils \
        binutils build-base file linux-headers \
        clang cmake ninja-build ninja-is-really-ninja \
        git \
        libarchive-tools \
        mold \
        musl musl-dev musl-libintl musl-utils \
        perl \
        pkgconf \
    && apk --no-cache upgrade \
    && rm -rf /var/cache/apk/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV CGO_ENABLED=0


FROM golang-builder AS aws-lc-builder
ARG image_build_date='2024-05-11'
ARG REPOPATH="github.com/aws/aws-lc"
WORKDIR /go/src/${REPOPATH}/
RUN git clone -j "$(nproc)" --no-tags --shallow-submodules --recurse-submodules --depth 1 --single-branch \
        "https://${REPOPATH}" ./

ENV CFLAGS='-O2 -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all' \
    CXXFLAGS='-O2 -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all' \
    LDFLAGS="-fuse-ld=mold -static-pie"
ENV PKG_CONFIG_ALL_STATIC=true \
    PKG_CONFIG="pkgconf --static --pure"
ARG TARGETARCH
WORKDIR /aws-lc-build/
RUN case "$TARGETARCH" in \
        amd64) export protect_branch='-fcf-protection=full';; \
        arm64) export protect_branch='-mbranch-protection=standard';; \
            *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    &&   CFLAGS="${CFLAGS}   ${protect_branch}" \
    && CXXFLAGS="${CXXFLAGS} ${protect_branch}" \
    && export CFLAGS CXXFLAGS \
    && cmake -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/aws-lc-install \
        -DBUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DFIPS=OFF \
        /go/src/${REPOPATH}/ \
    && ninja install \
    && strip /aws-lc-install/bin/bssl


FROM scratch
COPY --from=aws-lc-builder /aws-lc-install/ /aws-lc-install/
