# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/library/alpine:latest@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS base
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
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
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG CFLAGS
ARG CXXFLAGS
ENV   CFLAGS="${CFLAGS:-   -O2 -Wall -Wformat -Wformat=2 -Wconversion -Wimplicit-fallthrough -Werror=format-security -Werror=implicit -Werror=incompatible-pointer-types -Werror=int-conversion -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fexceptions -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -ftrivial-auto-var-init=zero -Wl,-z,nodlopen -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,--icf=safe}" \
    CXXFLAGS="${CXXFLAGS:- -O2 -Wall -Wformat -Wformat=2 -Wconversion -Wimplicit-fallthrough -Werror=format-security -Werror=implicit -Werror=incompatible-pointer-types -Werror=int-conversion -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fexceptions -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -ftrivial-auto-var-init=zero -Wl,-z,nodlopen -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,--icf=safe}"
ENV PKG_CONFIG="/usr/bin/pkgconf" \
    LDFLAGS="-fuse-ld=mold"
