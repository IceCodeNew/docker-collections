FROM mirror.gcr.io/library/alpine:latest AS base
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
ARG image_build_date='2024-05-11'
# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apk update; apk --no-progress --no-cache add \
        bash ca-certificates curl dos2unix file git grep libarchive-tools parallel pcre2-dev sed \
        python3 \
        binutils coreutils diffutils \
        build-base linux-headers patch \
        musl musl-dev musl-libintl musl-utils \
        pkgconf mold \
        clang compiler-rt \
        cmake ninja-build ninja-is-really-ninja \
        libtree; \
    apk --no-progress --no-cache upgrade; \
    rm -rf /var/cache/apk/*; \
    sed -i 's!/bin/ash!/bin/bash!' /etc/passwd; \
    mkdir -p "$HOME/.parallel"; \
    touch "$HOME/.parallel/will-cite"

ARG TARGETARCH
RUN case "$TARGETARCH" in \
        amd64) export protect_branch="-fcf-protection=full"; \
               export CPU_CFLAGS="-march=x86-64-v2";; \
        arm64) export protect_branch="-mbranch-protection=standard"; \
               export CPU_CFLAGS="-march=armv8.1-a+crypto";; \
            *) echo "unsupported architecture"; exit 1 ;; \
    esac
ENV PKG_CONFIG="/usr/bin/pkgconf" \
    LDFLAGS="-fuse-ld=mold" \
    CFLAGS="-O2 -ftree-vectorize -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong ${protect_branch} ${CPU_CFLAGS} -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all" \
    CXXFLAGS="-O2 -ftree-vectorize -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong ${protect_branch} ${CPU_CFLAGS} -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all"
