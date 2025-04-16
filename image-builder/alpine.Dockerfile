# syntax=mirror.gcr.io/docker/dockerfile:1

FROM mirror.gcr.io/library/alpine:latest AS base
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
ARG image_build_date=2024-06-23

RUN apk update; apk --no-progress --no-cache add \
        bash ca-certificates catatonit curl dos2unix file git grep libarchive-tools parallel pcre2-dev sed \
        python3 \
        binutils coreutils diffutils \
        build-base linux-headers patch \
        musl musl-dev musl-libintl musl-utils \
        pkgconf mold \
        clang compiler-rt \
        cmake samurai \
        libtree; \
    apk --no-progress --no-cache upgrade; \
    rm -rf /var/cache/apk/*; \
    sed -i 's!/bin/ash!/bin/bash!' /etc/passwd; \
    mkdir -p "$HOME/.parallel"; \
    touch "$HOME/.parallel/will-cite"

ARG CFLAGS
ARG CXXFLAGS
ENV CFLAGS="${CFLAGS:- -O2 -ftree-vectorize -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all}" \
    CXXFLAGS="${CXXFLAGS:- -O2 -ftree-vectorize -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all}"
ENV PKG_CONFIG="/usr/bin/pkgconf" \
    LDFLAGS="-fuse-ld=mold"
